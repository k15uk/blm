scriptencoding utf-8

" ####################
" # script valiables #
" ####################
let s:layouts = {}
let s:i = 0           " iterate the current_layout
let s:ignore_add_buffer = -1
let s:ignore_remove_buffer = 0
let s:preview_terminal = -1

let s:LAYOUT     = 'layout'
let s:WINDOW     = 'window'
let s:BUFFER     = 'buffer'
let s:VERTICAL   = 'vertical'
let s:HORIZONTAL = 'horizontal'
let s:CURRENT    = 'current'
let s:TERMINAL   = 'terminal'

" ##################
" # buffer control #
" ##################
" change_buffer
" @param vector : 0 = normal, 1 = reverse
" #param order  : 0 = terminal, -1(else) = else
function! blm#change_buffer( vector, order )
 " assignment buffer list
  let l:buffers = copy( s:layouts[s:i][s:WINDOW][winnr()][s:BUFFER] )
  if a:vector==1
    let l:buffers = reverse( l:buffers )
  endif

  if a:order == -1 && &buftype == s:TERMINAL
    wincmd t
  endif

  " find target buffer
  let l:target_buffer = -1
  let l:found_current_buffer = 0

  for buffer in l:buffers
    if buflisted( buffer ) && match( bufname( buffer ), s:TERMINAL.'.*' ) == a:order
      if l:target_buffer == -1
        let l:target_buffer = buffer
      endif
      if buffer == winbufnr( winnr() )
        " found current buffer -> flag stands
        let l:found_current_buffer = 1
      elseif l:found_current_buffer == 1
        " if flag stands -> target buffer
        let l:target_buffer = buffer
        break
      endif
    endif
  endfor

  if l:target_buffer == -1
    if a:order == 0
      " if the target buffer is not found
      " and when order is terminal -> open new terminal
      call blm#add_terminal()
    else
      call blm#change_buffer( a:vector, 0 )
    endif
  else
    " if find target buffer
    execute ':'.l:target_buffer.'b'
  endif
endfunction

function! blm#add_buffer()
  if s:chk_has_key() == -1 || s:ignore_add_buffer == -1
    return
  endif
  " check buffer in current layout buffer list
  if !has_key( s:layouts[s:i][s:WINDOW][winnr()], s:BUFFER )
    let s:layouts[s:i][s:WINDOW][winnr()][s:BUFFER] = [winbufnr( winnr( ) )]
  endif
  for buffer in s:layouts[s:i][s:WINDOW][winnr()][s:BUFFER]
    if buffer == winbufnr( winnr() )
      return
    endif
  endfor
  " add buffer on current layout buffer list
  call add( s:layouts[s:i][s:WINDOW][winnr()][s:BUFFER], winbufnr( winnr() ) )
  call s:update_layout()
endfunction

" when buffer close
function! blm#remove_buffer()
  if s:ignore_remove_buffer == -1
    pclose
    let s:ignore_remove_buffer = 0
    return
  endif
  if s:chk_has_key() == -1
    return
  endif

  let l:ignore_delete_buffer = -1
  for l:i in range( len( s:layouts[s:i][s:WINDOW][winnr()][s:BUFFER] ) )
    if s:layouts[s:i][s:WINDOW][winnr()][s:BUFFER][l:i] == winbufnr( winnr() )
      call remove( s:layouts[s:i][s:WINDOW][winnr()][s:BUFFER], l:i )
      break
    endif
  endfor

  if len( s:layouts[s:i][s:WINDOW][winnr()][s:BUFFER] ) == 0
    call remove( s:layouts[s:i][s:WINDOW], winnr() )
  endif

  let l:tmp = winbufnr( winnr() )

  if len( s:layouts[s:i][s:WINDOW] ) == 0
    call remove( s:layouts, s:i )
    if len( s:layouts ) > 0
      call blm#switch_layout( 1 )
    else
      quit
    endif
  else

    let l:ignore_delete_buffer = s:check_layout_has_buffer()

    if has_key( s:layouts[s:i][s:WINDOW], winnr() )
      call blm#change_buffer( -1, -1 )
    else
      close
    endif
  endif
  if l:ignore_delete_buffer == -1 && match(bufname(l:tmp),'terminal.*')==0
    execute ':bw!'.l:tmp
  endif

  call s:update_tabline()
endfunction

" ####################
" # terminal control #
" ####################
function! s:get_terminal_name()
  let l:cnt = 0
  while bufexists( s:TERMINAL.l:cnt )
    let l:cnt += 1
  endwhile
  return s:TERMINAL.l:cnt
endfunction

" terminal open
" param flg: 0  = newlayout(terminal only window)
"            else = terminal open by current window
function! blm#add_terminal()
  " disable add buffer
  let s:ignore_add_buffer = -1
  " create new window
  enew
  " enable add buffer
  let s:ignore_add_buffer = 0
  call termopen( &shell, { 'on_exit' : 'On_exit' } )
  " set buffer name by unique number
  execute ':f '.s:get_terminal_name()
  call s:update_layout()
  startinsert
endfunction

" toggle on preview window by terminal
function! blm#toggle_preview_term()
  if &previewwindow
    pclose
  end
  if s:preview_terminal == 0
    wincmd b
    close
    let s:preview_terminal = -1
  else
    let s:preview_terminal = 0
    call s:split( 'down' )
    resize 20
    wincmd b
    enew
    if bufexists( 'preview_terminal')
      execute ':'.bufnr('preview_terminal').'b'
    else
      call termopen( &shell, { 'on_exit' : 'On_exit' } )
      execute ':f preview_terminal'
    end
    startinsert
  endif
endfunction

" arg left, right, up, down
function! blm#split_terminal( vector )
  let s:ignore_add_buffer = -1
  call s:split( a:vector )
  enew
  let s:ignore_add_buffer = 0
  call blm#add_terminal()
endfunction

function! On_exit(job_id, code, event)
  if &previewwindow
    let s:ignore_remove_buffer = -1
  endif
  execute ':bw!'
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

  if s:preview_terminal == 0
    wincmd b
    close
    let s:preview_terminal = -1
  endif

  " get layout info
  let l:windows = {}
  for l:i in range( 1, winnr( '$' ) )
    let l:buffers = []
    try
      let l:buffers = s:layouts[s:i][s:WINDOW][l:i][s:BUFFER]
    catch
      let l:buffers = [winbufnr( l:i)]
    endtry
    let l:windows[l:i] = {}
    let l:windows[l:i][s:HORIZONTAL] = winwidth( l:i )
    let l:windows[l:i][s:VERTICAL] = winheight( l:i )
    let l:windows[l:i][s:CURRENT] = winbufnr( l:i )
    let l:windows[l:i][s:BUFFER] = l:buffers
  endfor
  let s:layouts[s:i] = {}
  let s:layouts[s:i][s:LAYOUT] = winlayout()
  let s:layouts[s:i][s:WINDOW] = l:windows

  call s:update_tabline()
endfunction

" split window
" @param layout = s:layouts[s:LAYOUT](Recursive)
function! s:split_window( layout )
  if a:layout[0] ==# 'row'
    for _ in range( len( a:layout[1] ) -1 )
      execute ':vsplit'
      execute ':wincmd h'
    endfor
    for window in a:layout[1]
      call s:split_window( window )
      execute ':wincmd l'
    endfor
  elseif a:layout[0] ==# 'col'
    for _ in range( len( a:layout[1] ) -1 )
      execute ':split'
      execute ':wincmd k'
    endfor
    for window in a:layout[1]
      call s:split_window( window )
      execute ':wincmd j'
    endfor
  endif
endfunction

" switch layout
" @param flg = vector on change
function! blm#switch_layout( flg )
  " disable add buffer
  let s:ignore_add_buffer = -1
  if &previewwindow
    pclose
  endif

  if s:preview_terminal == 0
    wincmd b
    close
    let s:preview_terminal = -1
  endif

  " reset window split
  if winnr( '$' ) != 1
    wincmd t
    only
  endif

  call s:switch_layout_key( a:flg )

  " split window by layout
  call s:split_window( s:layouts[s:i][s:LAYOUT] )

  let l:bufexist = 0
  wincmd t
  for layout in items( s:layouts[s:i][s:WINDOW] )
    if bufexists( layout[1][s:CURRENT] )
      let l:bufexist = 1
      execute ':b ' .layout[1][s:CURRENT]
      execute ':vertical resize ' .layout[1][s:HORIZONTAL]
      execute ':resize ' .layout[1][s:VERTICAL]
      wincmd w
    endif
  endfor

  if bufexist == 0
    call blm#switch_layout( a:flg )
  endif
  " enable add buffer
  let s:ignore_add_buffer = 0
endfunction

function! s:switch_layout_key( flg )
  " get layout to change
  let l:found_flg = -1
  let l:target_layout = -1
  for layout in items( s:layouts )
    if a:flg == 0 && l:target_layout == -1
      let l:target_layout = layout[0]
    endif
    if layout[0] == s:i
      if a:flg == 0
        let l:found_flg = 0
      elseif l:target_layout != -1
        break
      endif
    elseif l:found_flg == 0
      let l:target_layout = layout[0]
      break
    elseif a:flg != 0
      let l:target_layout = layout[0]
    end
  endfor
  let s:i = l:target_layout
endfunction

function! blm#add_layout()
  call s:update_layout()
  let s:i = 0
  while 0 == 0
    if has_key( s:layouts, s:i )
      let s:i += 1
    else
      break
    endif
  endwhile
  if winnr( '$' ) > 1
    only
  endif
  execute ':cd ~'
  call blm#add_terminal()
endfunction

function! s:split( vector )
  if a:vector ==# 'down'
    execute ':rightbelow split'
  elseif a:vector ==# 'up'
    execute ':leftabove split'
  elseif a:vector ==# 'left'
    execute ':leftabove vertical split'
  elseif a:vector ==# 'right'
    execute ':rightbelow vertical split'
  endif
endfunction

function! blm#split_window( vector )
  call s:split( a:vector )
  call s:update_layout()
endfunction

function! blm#get_layouts()
  let l:head = []
  for item in items( s:layouts )
    if item[0] == s:i
      call add( l:head, '[' . item[0] . ']' )
    else
      call add( l:head, ' ' . item[0] . ' ' )
    endif
  endfor
  return join( l:head , ',' )
endfunction

" #############################################
" # control window layout when closing buffer #
" #############################################
" alternate :q
cabbrev <silent>q bd
" alternate :Wq/wq
command! -nargs=0 Wq w | bd
cabbrev <silent>wq Wq

" #####################
" # ride on buftablne #
" #####################
function! s:update_tabline()
  if exists( '*buftabline#update' )
    call buftabline#update( 0 )
  endif
endfunction

" override
function! buftabline#user_buffers()
  if s:chk_has_key() == -1
    return []
  endif
	return filter( s:layouts[s:i][s:WINDOW][winnr()][s:BUFFER], 'buflisted( v:val ) && "quickfix" !=? getbufvar( v:val, "&buftype" )' )
endfunction

" ###################
" # other functions #
" ###################
" initialize
function! blm#init()
  call s:update_layout()
  let s:ignore_add_buffer = 0
  call termopen( &shell, { 'on_exit' : 'On_exit' } )
  execute ':f '.s:TERMINAL.'0'
  call s:update_tabline()
  set nonumber
  startinsert
endfunction

" when buffer enter
function! blm#enter_buffer()
  if &buftype == s:TERMINAL
    set nonumber
    startinsert
  else
    set number
    stopinsert
  endif
  try
    execute ':cd '.expand( '%:p:h' )
  catch
    execute ':cd ~'
  endtry
  call blm#add_buffer()
endfunction

function! s:chk_has_key()
  if !has_key( s:layouts, s:i ) ||
        \ !has_key( s:layouts[s:i], s:WINDOW ) ||
        \ !has_key( s:layouts[s:i][s:WINDOW], winnr() )
    return -1
  endif
  return 0
endfunction

function! s:check_layout_has_buffer()
  for l:layout in items( s:layouts )
    for l:window in items( l:layout[1][s:WINDOW] )
      for l:buffer in l:window[1][s:BUFFER]
        if l:buffer == winbufnr( winnr() )
          return 0
        endif
      endfor
    endfor
  endfor
  return -1
endfunction
