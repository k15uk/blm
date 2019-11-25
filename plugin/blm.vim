if exists('g:loaded_blm')
	finish
endif
let g:loaded_blm = 1

augroup VimWrapper
  autocmd! BufHidden * call blm#layout_update()
	autocmd! VimWrapper VimEnter * if @%==''|call blm#init()
	autocmd! VimWrapper TermOpen,BufEnter * call blm#buf_enter()
	autocmd! VimWrapper BufDelete * call blm#buf_close()
	autocmd! VimWrapper TermClose * call blm#term_close()
augroup END
