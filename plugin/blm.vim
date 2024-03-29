if exists('g:loaded_blm')
  finish
endif
let g:loaded_blm = 1

augroup blm
  autocmd!
  autocmd VimEnter   * if @%==''|call blm#init()
  autocmd TermEnter  * call blm#enter_buffer()
  autocmd BufEnter   * call blm#enter_buffer()
  autocmd BufAdd     * call blm#add_buffer()
  autocmd FileType gitcommit,gitrebase,gitconfig set bufhidden=delete
augroup END
