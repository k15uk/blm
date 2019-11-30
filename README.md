blm buffer layout manager
=========================

## About
blm helps you use vim like a terminal multiplexer.

The goal is a clone of byobu in vim

blm manages the layout of the vim buffer window

## Usage
Example (dein)

[[plugins]]

repo = 'k15uk/blm'

hook_add = '''

	nnoremap <silent><C-f>j :rightbelow split         <CR>:call blm#term_add(-1)<CR>
	nnoremap <silent><C-f>k :leftabove  split         <CR>:call blm#term_add(-1)<CR>
	nnoremap <silent><C-f>h :leftabove  vertical split<CR>:call blm#term_add(-1)<CR>
	nnoremap <silent><C-f>l :rightbelow vertical split<CR>:call blm#term_add(-1)<CR>

	nnoremap <silent><Tab>   :call blm#buffer_change(0,-1)<cr>
	nnoremap <silent><s-tab> :call blm#buffer_change(1,-1)<CR>

	nnoremap <silent><M-.> :call blm#switch_layout(0)<CR>
	nnoremap <silent><M-,> :call blm#switch_layout(1)<CR>

	nnoremap <silent><M-Tab>   :call blm#buffer_change(0, 1)<CR>
	nnoremap <silent><M-S-Tab> :call blm#buffer_change(1, 1)<CR>

	nnoremap <silent><M-Space> :call blm#term_preview_toggle()<CR>

	nnoremap <silent><M-Enter> :call blm#term_add(0)<CR>
	
'''
