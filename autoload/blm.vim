" ##################
" # buffer control #
" ##################
" change_buffer
" @param vector : 0=normal, 1=reverse
" #param order  : 0=terminal, -1(else)=else
function! blm#change_buffer(vector,order)
 " assignment buffer list
	let l:buffers=[]
  for buffer in s:layouts[s:current_layout]['buffers']
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
	if l:order==-1 && &buftype=='terminal'
		wincmd t
	endif

  " find target buffer
	let l:target_buffer=-1
	let l:found_current_buffer=0

	for buffer in l:buffers
		if buflisted(buffer)&&match(bufname(buffer),'terminal.*')==l:order
			if l:target_buffer==-1
				let l:target_buffer=buffer
      endif
			if buffer==bufnr('%')
        " found current buffer -> flag stands
				let l:found_current_buffer=1
			elseif l:found_current_buffer==1
        " if flag stands -> target buffer
				let l:target_buffer=buffer
        break
			endif
		endif
	endfor

	if l:found_current_buffer==0&&l:order==0
		" if the target buffer is not found
    " and when order is terminal -> open new terminal
		call blm#add_term(-1)
  else
    " if find target buffer
		execute ':'.l:target_buffer.'b'
	endif
endfunction

let s:ignore_add_buffer=1
function! s:add_buffer()
  if s:ignore_add_buffer==0
    " check buffer in current layout buffer list
    if !has_key(s:layouts[s:current_layout],'buffers')
      let s:layouts[s:current_layout]['buffers']=[bufnr('%')]
    endif
    for i in range(len(s:layouts[s:current_layout]['buffers']))
      if s:layouts[s:current_layout]['buffers'][i] == bufnr('%')
        return
      endif
    endfor
    " add buffer on current layout buffer list
    call add(
          \s:layouts[s:current_layout]['buffers']
          \,bufnr('%')
          \)
    call s:update_layout()
  endif
endfunction

" when buffer close
function! s:remove_buffer()
  for i in range(len(s:layouts[s:current_layout]['windows']))
    if s:layouts[s:current_layout]['windows'][i]['buffer'] == bufnr('%')
      call remove(s:layouts[s:current_layout]['windows'],i)
      break
    endif

    for i in range(len(s:layouts[s:current_layout]['buffers']))
      if s:layouts[s:current_layout]['buffers'][i] == bufnr('%')
        call remove(s:layouts[s:current_layout]['buffers'],i)
        break
      endif
    endfor

    if len(s:layouts[s:current_layout]['windows']) == 0
      call remove(s:layouts,s:current_layout)
      if len(s:layouts) == 0
        quit
      else
        call blm#switch_layout(-1)
      endif
    endif
  endfor
endfunction


" ####################
" # terminal control #
" ####################
" terminal open
" param flg: 0   =newlayout(terminal only window)
"            else=terminal open by current window
function! blm#add_term(flg)
	if a:flg==0
    call s:update_layout()
    let s:current_layout=len(s:layouts)
    call add(s:layouts, {})
	endif
	if a:flg==0&&winnr('$')>1
		only
	endif
  " disable add buffer
  let s:ignore_add_buffer=1
  " create new window
	enew
  " enable add buffer
  let s:ignore_add_buffer=0
	call termopen(&shell,{})
  " get unique number
	let l:cnt=0
	while bufexists('terminal'.l:cnt)
		let l:cnt+=1 
	endwhile
  " set buffer name by unique number 
	execute ':f terminal'.l:cnt
  call s:update_layout()
endfunction

" toggle on preview window by terminal
function! blm#toggle_preview_term()
	if &previewwindow
		pclose
	else
		pedit
		wincmd p
		call blm#change_buffer(0,0)
		resize 14
	endif
endfunction

" ###################################
" # window layout control functions #
" ###################################
let s:layouts=[]
let s:current_layout=0

" layout update
function! s:update_layout()
  " close preview window
  if &previewwindow
    pclose
  endif

  " get layout info 
  let l:windows=[]
  for i in range(1,winnr('$'))
    let l:window={
          \'buffer':winbufnr(i)
          \,'width':winwidth(i)
          \,'height':winheight(i)}
    call add(l:windows,l:window)
  endfor

  if !has_key(s:layouts[s:current_layout],'buffers')
    let s:layouts[s:current_layout]['buffers']=[bufnr('%')]
  endif
  let s:layouts[s:current_layout] = {
        \'layout':winlayout()
        \,'windows':l:windows
        \, 'buffers':s:layouts[s:current_layout]['buffers']
        \}
endfunction

" split window
" @param layout = s:layouts['layout'](Recursive)
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
  call s:update_layout()
	if &previewwindow
    pclose
	endif

	" reset window split
	if winnr('$')!=1
		wincmd t
		only
	endif

	" get layout to change
	if a:flg==0
    let s:current_layout+=1
  else
    let s:current_layout-=1
	endif
  if s:current_layout<0
    let s:current_layout=len(s:layouts)-1
  elseif s:current_layout>len(s:layouts)-1
    let s:current_layout=0
  endif

  " split window by layout
	call s:split_window(s:layouts[s:current_layout]['layout'])
	
  let l:bufexist=0
	wincmd t
	for layout in s:layouts[s:current_layout]['windows']
    if bufexists(layout['buffer'])
      let l:bufexist=1
      execute ":b " .layout['buffer']
      execute ":vertical resize " .layout['width']
      execute ":resize " .layout['height']
      wincmd w
    endif
	endfor

  if bufexist==0
    call blm#switch_layout(a:flg)
  endif
endfunction

" #############################################
" # control window layout when closing buffer #
" #############################################
"  count on opened buffer
function! s:get_buffers_count()
  let l:count=0
  for i in range( 1 , bufnr('$') )
    if buflisted(i)
      let l:count = l:count + 1
    endif
  endfor
  return l:count
endfunction

" alternate :q command(buffer close/vim close)
function! blm#close()
  " close preview window
  silent! wincmd P
  if &previewwindow
    pclose
    return
  endif
  if getcmdwintype()!=''
    " close command line window
    quit
  elseif s:get_buffers_count()<=1
    " when last buffer, vim close
    quit
  else
    " close buffer
    call s:remove_buffer()
    execute ':bw '.bufnr('%')
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
  let s:ignore_add_buffer=0
	call termopen(&shell,{})
  call add(s:layouts, {})
  call s:update_layout()
	f terminal0
	startinsert
endfunction

" when buffer enter
function! blm#enter_buffer()
	if &buftype=='terminal'
		set nonumber
    startinsert
	else
		set number 
    stopinsert
	endif
	try
    execute ':cd ' .expand('%:p:h')
	catch
		execute ':cd ~'
	endtry
  call s:add_buffer()
endfunction

function! blm#add_buffer()
  call s:add_buffer()
endfunction

" when terminal close
function! blm#close_term()
  call blm#close()
endfunction

" for debug
function! blm#echo_layouts()
  echo s:layouts
endfunction
function! blm#echo_layout()
  echo s:layouts[s:current_layout]['layout']
endfunction
function! blm#echo_current_buffers()
  echo s:layouts[s:current_layout]['buffers']
endfunction
function! blm#echo_windows()
  echo s:layouts[s:current_layout]['windows']
endfunction
