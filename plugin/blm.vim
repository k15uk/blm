if exists('g:loaded_blm')
	finish
endif
let g:loaded_blm = 1

augroup VimWrapper
	autocmd! VimWrapper VimEnter * if @%==''|call blm#init()
	autocmd! VimWrapper TermOpen,TermEnter,BufEnter * call blm#enter_buffer()
	autocmd! VimWrapper BufAdd * call blm#add_buffer()
	autocmd! VimWrapper TermClose * call blm#close_term()
augroup END
