" ##################
" # buffer control #
" ##################
" buffer_change
" @param vector : 0=normal, 1=reverse
" #param order  : 0=terminal, -1(else)=else
function! blm#buffer_change(vector,order)
	let l:list=s:layouts[s:current_layout]['windows'] " assignment window list

  " reverse depending on argument
	if a:vector==1
		let l:list=reverse(l:list)
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
	let l:find_current_buffer=0

	for window in l:list
		if buflisted(window['buffer'])&&match(bufname(window['buffer']),'terminal.*')==l:order
			if bufnr(window['buffer'])==bufnr('%') " find current buffer -> flag stands
				let l:find_current_buffer=1
			elseif l:find_current_buffer==0&&l:target_buffer==-1 " current buffer is not find = last buffer
				let l:target_buffer=bufnr(window['buffer'])
			elseif l:find_current_buffer==1 " if flag stands -> target buffer
				let l:target_buffer=bufnr(window['buffer'])
				break
			endif
		endif
	endfor

	if l:target_buffer!=-1
    " if find target buffer
		execute ':'.l:target_buffer.'b'
	elseif l:find_current_buffer==0&&l:order==0
		" if the target buffer is not found and when order is terminal -> open new terminal
		call blm#term_add(-1)
	endif
endfunction

" ####################
" # terminal control #
" ####################
" terminal open
" param flg: 0=newlayout(terminal only window) else=terminal open by current window
function! blm#term_add(flg)
	call blm#layout_update()
  let s:layout_update_ignore=1 " layout_update() disable ( ignition by 'only' )
	if a:flg==0&&winnr('$')>1
		only
	endif
	enew " create new window
	call termopen(&shell,{'on_exit': 'blm#term_close'}) " terminal open
  " get unique number
	let l:cnt=0
	while bufexists('terminal'.l:cnt)
		let l:cnt+=1 
	endwhile
  " set buffer name by unique number 
	execute ':f terminal'.l:cnt
	let s:layout_update_ignore=0 " layout_update() enable
	if a:flg==0
		let s:current_layout=len(s:layouts) " list layout[] add
	endif
endfunction

" toggle on preview window by terminal
function! blm#term_preview_toggle()
	if &previewwindow
		pclose
	else
		pedit
		wincmd p
		call blm#buffer_change(0,0)
		resize 14
	endif
endfunction

" ###################################
" # window layout control functions #
" ###################################
let s:layouts=[]
let s:current_layout=0
let s:layout_update_ignore=0

" layout update
function! blm#layout_update()
  " when switching layouts, layout update are disable
	if s:layout_update_ignore==0
    " close preview window
    if &previewwindow
      pclose
    endif

    " get layout info 
		let l:windows=[]
		for i in range(1,winnr('$'))
			let l:window={'buffer':winbufnr(i),'width':winwidth(i),'height':winheight(i)}
			call add(l:windows,l:window)
		endfor

    " set layout info to layouts[]
    if len(s:layouts) <= s:current_layout
      call add(s:layouts, {})
    endif
    let s:layouts[s:current_layout] = {'layout':winlayout(),'windows':l:windows}
	endif
endfunction

" split window
" @param layout = s:layouts['layout'](Recursive)
function! s:split_window(layout)
  if a:layout[0]=='row'
    for a in range(len(a:layout[1])-1)
      execute ':vsplit'
      execute ':wincmd h'
    endfor
    for win in a:layout[1]
      call s:split_window(win)
      execute ':wincmd l'
    endfor
  elseif a:layout[0]=='col'
    for a in range(len(a:layout[1])-1)
      execute ':split'
      execute ':wincmd k'
    endfor
    for win in a:layout[1]
      call s:split_window(win)
      execute ':wincmd j'
    endfor
  endif
endfunction

" switch layout
" @param flg=vector on change
function! blm#switch_layout(flg)
	if &previewwindow
    pclose
	endif
	call blm#layout_update()

  let s:layout_update_ignore=1 " layout_update() disable 

	" reset window split
	if winnr('$')!=1
		wincmd t
		only
	endif

	" get layout to change
	if a:flg==0
    let s:current_layout += 1
  else
    let s:current_layout -= 1
	endif
  if s:current_layout < 0
    let s:current_layout = len(s:layouts) - 1
  elseif s:current_layout > len(s:layouts) - 1
    let s:current_layout = 0
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

  let s:layout_update_ignore=0 " layout_update() enable 
  if bufexist==0
    blm#switch_layout(a:flg)
  endif
endfunction


" #############################################
" # control window layout when closing buffer #
" #############################################
"  count on opened buffer
function! blm#get_buf_count()
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
  elseif blm#get_buf_count()<=1
    " when last buffer, vim close
    quit
  else
    " close buffer
    let l:current_buffer=bufnr('%')
    call blm#buffer_change(-1,0)
    execute ':bw '.l:current_buffer
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
  call blm#layout_update()
	call termopen(&shell,{})
	f terminal0
	call blm#buf_enter()
	startinsert
endfunction

" when buffer enter
function! blm#buf_enter()
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
endfunction

" when buffer close
function! blm#buf_close()
  for i in range(len(s:layouts[s:current_layout]['windows']))
    if s:layouts[s:current_layout]['windows'][i]['buffer'] == bufnr('%')
      call remove(s:layouts[s:current_layout]['windows'],i)
    endif
  endfor
endfunction

" when terminal close
function! blm#term_close()
  bd!
	if bufname('%')==''
		quit
	endif
endfunction
