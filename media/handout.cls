%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% HANDOUT document class
%%%
%%% Change history:
%%%-----------------
%%% 04/01/98  Creation (JWJ).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%
%%% Commands:
%%% ---------
%%%    \coursetitle
%%%    \handouttitle
%%%    \handoutauthor  - Defaults to nothing.
%%%    \handoutdate    - Defaults to \today.
%%%    \semestertitle
%%%    \makeboxtitle
%%%    \matlab
%%%
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{handout}[1998/04/29]
\RequirePackage{fancyheadings}
\RequirePackage{hhline}
\RequirePackage{xspace}
\RequirePackage{array}
\RequirePackage{amssymb}
\LoadClass{article}

\textwidth=17.5cm
\textheight=23.2cm
\hoffset=-2.5cm

\pagestyle{fancy}

%--------------------------------------------------------------------------
% Configure default variables.
%--------------------------------------------------------------------------
\newcommand{\coursetitle}{The Course}
\newcommand{\handouttitle}{The Handout}
\newcommand{\semestertitle}{The Semester}
\newcommand{\handoutauthor}{}
\newcommand{\handoutdate}{\today}

%--------------------------------------------------------------------------
% Setup the page header.
%--------------------------------------------------------------------------
\lhead[\coursetitle]{\coursetitle}
\chead[\handouttitle]{\handouttitle}
\rhead[\semestertitle]{\semestertitle}
\setlength{\headsep}{10pt}

%--------------------------------------------------------------------------
% Reconfigure the section header function.
%--------------------------------------------------------------------------
\renewcommand{\labelitemi}{$\square$}
\setcounter{secnumdepth}{3}
%\setlength{\parindent}{0mm}
\makeatletter
\renewcommand{\section}{\@startsection
   {section}%                       % name
   {1}%                             % level
   {0cm}%                           % indent
   {-\baselineskip}%                % beforeskip
   {0.5\baselineskip}%              % afterskip
   {\normalfont\Large\bfseries}}%   % style
\makeatother

%--------------------------------------------------------------------------
% Command for creating the title box.
%--------------------------------------------------------------------------
\newcommand{\makeboxtitle}
{
   \begin{tabular}{||p{10cm}||l}
      \hhline{|t:=:t|} \\
      \centering{\Large \bf{\coursetitle}} & \\
      \centering{\Large \bf{\handouttitle}} & \\
      {\tiny \handoutauthor{} - \handoutdate} & \\
      \hhline{|b:=:b|}
   \end{tabular}
}


%--------------------------------------------------------------------------
% Nice commands
%--------------------------------------------------------------------------
\newcommand{\matlab}{\textnormal{\textsc{Matlab{}}}\xspace}
\newcommand{\erithacus}{\textnormal{\textsc{Erithacus}}\xspace}

