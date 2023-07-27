syntax on

filetype on             " 检测文件的类型
filetype plugin on
filetype indent on

set fencs=utf-8,gbk
set number              " 显示行号
set cursorline          " 用浅色高亮当前行

set ruler               " 在编辑过程中，在右下角显示光标位置的状态行
set laststatus=2        " 显示状态栏 默认值为 1, 无法显示状态栏

set tabstop=4           " Tab键的宽度
set softtabstop=4
set shiftwidth=4        " 统一缩进为4
set expandtab           " 设置缩进用空格来表示

set autoindent          " vim使用自动对齐，也就是把当前行的对齐格式应用到下一 自动缩进
set cindent             " cindent是特别针对C语言语法自动缩进
set smartindent         " 依据上面的对齐格式，智能的选择对齐方式，对于类似C语言编写上有用

set scrolloff=3         " 光标移动到buffer的顶部和底部时保持3行距离

set incsearch           " 输入搜索内容时就显示搜索结果
set hlsearch            " 搜索时高亮显示被找到的文本

set autoread			" 自动加载

" 粘贴代码自动缩进窜行
set pastetoggle=<F9>
