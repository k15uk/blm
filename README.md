blm buffer layout manager
=========================

## About
blm helps you use vim like a terminal multiplexer.

The goal is a clone of byobu in vim

blm manages the layout of the vim buffer window

## Installation

### on Dein
```vim
[[plugins]]
repo = 'k15uk/blm'
```

### on Pathogen

``` bash
cd ~/.vim/bundle
git clone https://github.com/k15uk/blm
```

### on Vundle
``` vim
Plugin 'k15uk/blm'
```

### on Vim-Plug
``` vim
Plug 'k15uk/blm'
```

### Usage
#### blm#split_window(arg)
arg:down/up/left/right

splitting_window

#### blm#split_terminalarg)
Something like a split-window in byobu

arg:down/up/left/right

Create terminal buffer,after splitting_window

#### blm#change_buffer(arg1,arg2)
Changing buffer (buffer of current window)

arg1:0 is switching orfer by asc

arg1:1 is switching orfer by desc

arg2:0  is switching of terminal buffer obly

arg2:-1 is switching of other buffer

#### blm#switch_layout(arg)
Switching layout (Like switching tabs)

arg:0 is switching orfer by asc

arg:1 is switching orfer by desc

#### blm#add_layout()
Create layout (Like new tab)

Something like a new-window in byobu

#### blm#add_terminal()
Open terminal on current window.

### Example
``` vim
nnoremap <silent>sj :call blm#split_window('down' )<CR>
nnoremap <silent>sk :call blm#split_window('up'   )<CR>
nnoremap <silent>sh :call blm#split_window('left' )<CR>
nnoremap <silent>sl :call blm#split_window('right')<CR>

nnoremap <silent><C-f>j :call blm#split_terminal('down' )<CR>
nnoremap <silent><C-f>k :call blm#split_terminal('up'   )<CR>
nnoremap <silent><C-f>h :call blm#split_terminal('left' )<CR>
nnoremap <silent><C-f>l :call blm#split_terminal('right')<CR>

nnoremap <Tab>     :call blm#change_buffer(0,-1)<CR>
nnoremap <S-Tab>   :call blm#change_buffer(1,-1)<CR>
nnoremap <M-Tab>   :call blm#change_buffer(0, 0)<CR>
nnoremap <M-S-Tab> :call blm#change_buffer(1, 0)<CR>

nnoremap <silent><M-.> :call blm#switch_layout(0)<CR>
nnoremap <silent><M-,> :call blm#switch_layout(1)<CR>

nnoremap <silent><M-Space> :call blm#toggle_preview_term()<CR>

nnoremap <silent><M-Enter> :call blm#add_layout()<CR>

nnoremap <silent><M-t> :call blm#add_terminal()<CR>
```
