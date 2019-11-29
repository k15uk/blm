scriptencoding utf-8

" ##################
" #  #
" ##################
let s:layouts={}
let s:i=0           " iterate the current_layout
let s:LAYOUT    ='layout'
let s:WINDOW    ='window'
let s:BUFFER    ='buffer'
let s:VERTICAL  ='vertical'
let s:HORIZONTAL='horizontal'
let s:CURRENT   ='current'
let s:TERMINAL  ='terminal'

" ##################
" # buffer control #
" ##################
" change_buffer
" @param vector : 0=normal, 1=reverse
" #param order  : 0=terminal, -1(else)=else
function! s:change_buffer(vector,order)
 " assignment buffer list
  let l:buffers=[]
  for buffer in s:layouts[s:i][s:WINDOW][winnr()][s:BUFFER]
    call add(l:buffers,buffer)
  endfor

  " reverse depending on argument
  if a:vector==1
    let l:buffers=reverse(l:buffers)
  endif

  " assignment args
  if a:order==0
    let l:order=0
  else
    let l:order=-1
  endif
  if l:order==-1 && &buftype==s:TERMINAL
    wincmd t
  endif

  " find target buffer
  let l:target_buffer=-1
  let l:found_current_buffer=0

  for buffer in l:buffers
    if buflisted(buffer)&&match(bufname(buffer),s:TERMINAL.'.*')==l:order
      if l:target_buffer==-1
        let l:target_buffer=buffer
      endif
      if buffer==winbufnr(winnr())
        " found current buffer -> flag stands
        let l:found_current_buffer=1
      elseif l:found_current_buffer==1
        " if flag stands -> target buffer
        let l:target_buffer=buffer
        break
      endif
    endif
  endfor

  if l:target_buffer==-1&&l:order==0
    " if the target buffer is not found
    " and when order is terminal -> open new terminal
    call s:add_terminal(-1)
  else
    " if find target buffer
    execute ':'.l:target_buffer.'b'
  endif
endfunction

let s:ignore_add_buffer=-1
function! blm#add_buffer()
  if s:chk_has_key()==-1||s:ignore_add_buffer==-1
    return
  endif
  " check buffer in current layout buffer list
  if !has_key(s:layouts[s:i][s:WINDOW][winnr()],s:BUFFER)
    let s:layouts[s:i][s:WINDOW][winnr()][s:BUFFER]=[winbufnr(winnr())]
  endif
  for i in range(len(s:layouts[s:i][s:WINDOW][winnr()][s:BUFFER]))
    if s:layouts[s:i][s:WINDOW][winnr()][s:BUFFER][i] == winbufnr(winnr())
      return
    endif
  endfor
  " add buffer on current layout buffer list
  call add(s:layouts[s:i][s:WINDOW][winnr()][s:BUFFER],winbufnr(winnr()))
  call s:update_layout()
endfunction

" when buffer close
function! blm#remove_buffer(flg)
  if s:chk_has_key() == -1
    return
  endif
  for l:i in range(len(s:layouts[s:i][s:WINDOW][winnr()][s:BUFFER]))
    if s:layouts[s:i][s:WINDOW][winnr()][s:BUFFER][l:i] == winbufnr(winnr())
      call remove(s:layouts[s:i][s:WINDOW][winnr()][s:BUFFER],l:i)
      break
    endif
  endfor

  if len(s:layouts[s:i][s:WINDOW][winnr()][s:BUFFER])==0
    call remove(s:layouts[s:i][s:WINDOW],winnr())
  endif

  let l:tmp=winbufnr(winnr())

  if len(s:layouts[s:i][s:WINDOW])==0
    call remove(s:layouts,s:i)
    if len(s:layouts)>0
      call blm#switch_layout(1)
    else
      quit
    endif
  else
    let l:ignore_delete_buffer=-1
    for l:i in range(len(s:layouts))
      if !has_key(s:layouts,l:i)
        continue
      endif

      for l:j in range(len(s:layouts[l:i][s:WINDOW]))
        if !has_key(s:layouts[l:i][s:WINDOW],l:j)
          continue
        endif

        for l:k in range(len(s:layouts[l:i][s:WINDOW][l:j][s:BUFFER]))
          if s:layouts[l:i][s:WINDOW][l:j][s:BUFFER][l:k] == winbufnr(winnr())
            let l:ignore_delete_buffer=0
            break
          endif
        endfor
      endfor
    endfor

    if has_key(s:layouts[s:i][s:WINDOW],winnr())
      call blm#switch_buffer(-1)
    else
      close
    endif
  endif

  if a:flg==0&&l:ignore_delete_buffer==-1
    execute ':bd'.l:tmp
  endif

  call s:update_tabline()
endfunction

" arg 0:new layout, -1:current window
function! blm#add_terminal(proc)
  call s:add_terminal(a:proc)
endfunction

" arg left,right,up,down
function! blm#split_terminal(vector)
  let s:ignore_add_buffer=-1
  call s:split(a:vector)
  enew
  let s:ignore_add_buffer=0
  call s:add_terminal(-1)
endfunction

function! s:split(vector)
  if a:vector=='down'
    execute ':rightbelow split'
  elseif a:vector=='up'
    execute ':leftabove split'
  elseif a:vector=='left'
    execute ':leftabove vertical split'
  elseif a:vector=='right'
    execute ':rightbelow vertical split'
  endif
endfunction

function! blm#split_window(vector)
  call s:split(a:vector)
  call s:update_layout()
endfunction

" arg 0,1
function! blm#switch_buffer(vector)
  call s:change_buffer(a:vector,&buftype==s:TERMINAL ? 0 : -1)
endfunction

" ####################
" # terminal control #
" ####################
function! s:get_terminal_name()
  let l:cnt=0
  while bufexists(s:TERMINAL.l:cnt)
    let l:cnt+=1
  endwhile
  return s:TERMINAL.l:cnt
endfunction

" terminal open
" param flg: 0   =newlayout(terminal only window)
"            else=terminal open by current window
function! s:add_terminal(flg)
  if a:flg==0
    call s:update_layout()
    call s:add_layout()
  endif
  if a:flg==0&&winnr('$')>1
    only
  endif
  " disable add buffer
  let s:ignore_add_buffer=-1
  " create new window
  enew
  " enable add buffer
  let s:ignore_add_buffer=0
  call termopen(&shell,{})
  " set buffer name by unique number 
  execute ':f '.s:get_terminal_name()
  call s:update_layout()
  set nonumber
  startinsert
endfunction

" toggle on preview window by terminal
function! blm#toggle_preview_term()
  if &previewwindow
    pclose
  else
    pedit
    wincmd p
    call s:change_buffer(0,0)
    resize 14
  endif
endfunction

" ###################################
" # window layout control functions #
" ###################################
" layout update
function! s:update_layout()
  " close preview window
  if &previewwindow
    pclose
  endif

  " get layout info 
  let l:windows={}
  for l:i in range(1,winnr('$'))
    let l:buffers=[]
    try
      let l:buffers=s:layouts[s:i][s:WINDOW][l:i][s:BUFFER]
    catch
      let l:buffers=[winbufnr(l:i)]
    endtry
    let l:windows[l:i]={}
    let l:windows[l:i][s:HORIZONTAL]=winwidth(l:i)
    let l:windows[l:i][s:VERTICAL]=winheight(l:i)
    let l:windows[l:i][s:CURRENT]=winbufnr(l:i)
    let l:windows[l:i][s:BUFFER]=l:buffers
  endfor
  let s:layouts[s:i] = {}
  let s:layouts[s:i][s:LAYOUT]=winlayout()
  let s:layouts[s:i][s:WINDOW]=l:windows

  call s:update_tabline()
endfunction

" split window
" @param layout = s:layouts[s:LAYOUT](Recursive)
function! s:split_window(layout)
  if a:layout[0]=='row'
    for _ in range(len(a:layout[1])-1)
      execute ':vsplit'
      execute ':wincmd h'
    endfor
    for window in a:layout[1]
      call s:split_window(window)
      execute ':wincmd l'
    endfor
  elseif a:layout[0]=='col'
    for _ in range(len(a:layout[1])-1)
      execute ':split'
      execute ':wincmd k'
    endfor
    for window in a:layout[1]
      call s:split_window(window)
      execute ':wincmd j'
    endfor
  endif
endfunction


" switch layout
" @param flg=vector on change
function! blm#switch_layout(flg)
  " disable add buffer
  let s:ignore_add_buffer=-1
  if &previewwindow
    pclose
  endif

  " reset window split
  if winnr('$')!=1
    wincmd t
    only
  endif

  call s:switch_layout_key(a:flg)

  " split window by layout
  call s:split_window(s:layouts[s:i][s:LAYOUT])

  let l:bufexist=0
  wincmd t
  for layout in items(s:layouts[s:i][s:WINDOW])
    if bufexists(layout[1][s:CURRENT])
      let l:bufexist=1
      execute ":b " .layout[1][s:CURRENT]
      execute ":vertical resize " .layout[1][s:HORIZONTAL]
      execute ":resize " .layout[1][s:VERTICAL]
      wincmd w
    endif
  endfor

  if bufexist==0
    call blm#switch_layout(a:flg)
  endif
  " enable add buffer
  let s:ignore_add_buffer=0
endfunction

function! s:switch_layout_key(flg)
  " get layout to change
  let l:found_flg=-1
  let l:target_layout=-1
  for layout in items(s:layouts)
    if a:flg==0&&l:target_layout==-1
      let l:target_layout=layout[0]
    endif
    if layout[0]==s:i
      if a:flg==0
        let l:found_flg=0
      elseif l:target_layout!=-1
        break
      endif
    elseif l:found_flg==0
      let l:target_layout=layout[0]
      break
    elseif a:flg!=0
      let l:target_layout=layout[0]
    end
  endfor
  let s:i=l:target_layout
endfunction

function! s:add_layout()
  let s:i=0
  while 0==0
    if has_key(s:layouts,s:i)
      let s:i+=1
    else
      break
    endif
  endwhile
endfunction

" #############################################
" # control window layout when closing buffer #
" #############################################
" alternate :q command(buffer close/vim close)
function! blm#close()
  if getcmdwintype()!=''
    " close command line window
    quit
  else
    " close buffer
    call blm#remove_buffer(0)
  endif
endfunction

" alternate :q
cabbrev <silent>q call blm#close()
" alternate :Wq/wq
command! -nargs=0 Wq w | call blm#close()
cabbrev <silent>wq Wq

" ###############################
" # called by autocmd functions #
" ###############################
" initialize
function! blm#init()
  call s:update_layout()
  let s:ignore_add_buffer=0
  call termopen(&shell,{})
  execute ':f '.s:TERMINAL.'0'
  call s:update_tabline()
  set nonumber
  startinsert
endfunction

" when buffer enter
function! blm#enter_buffer()
  if &buftype==s:TERMINAL
    set nonumber
    startinsert
  else
    set number 
    stopinsert
  endif
  try
    execute ':cd '.expand('%:p:h')
  catch
    execute ':cd ~'
  endtry
  call blm#add_buffer()
endfunction

function! s:chk_has_key()
  if !has_key(s:layouts,s:i)||
        \ !has_key(s:layouts[s:i],s:WINDOW)||
        \ !has_key(s:layouts[s:i][s:WINDOW],winnr())
    return -1
  endif
  return 0
endfunction

let s:dirsep = fnamemodify(getcwd(),':p')[-1:]
function! blm#rendering_tabline()
  if s:chk_has_key() == -1
    return
  endif
  let l:result=''
  for l:buffer in s:layouts[s:i][s:WINDOW][winnr()][s:BUFFER]
    if winbufnr(winnr())==buffer
      let l:result.='%T%#TabLineSel#'
    else
      let l:result.='%T%#PmenuSel#'
    endif
    let l:bufpath = bufname(l:buffer)
    let l:tabpath = fnamemodify(l:bufpath, ':p:~:.')
    let l:tabsep = strridx(l:tabpath, s:dirsep, strlen(l:tabpath) - 2)
    let l:tablabel = l:tabpath[l:tabsep + 1:]
    let l:result.=l:tablabel.' '
  endfor
  return l:result
endfunction

function! s:update_tabline()
  set tabline=%!blm#rendering_tabline()
endfunction
