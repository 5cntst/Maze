
/* 
		5cntst
		15-12-2015
 */



:- dynamic cell/3.
:- dynamic path/2.



% ------------------------------ ГРАФИЧЕСКИЙ ИНТЕРФЕЙС ------------------------



/* Главная функция */
play_maze :-
	/* Главное окно приложения */
	new(MainWindow, dialog('Maze Generator')),
	/* Селекторы */
	new(WidthSelector, int_item(width, low := 2, high := 70, default := 20)),
	new(HeightSelector, int_item(height, low := 2, high := 40, default := 10)),
	/* Область отрисовки лабиринта (рекомендуемые размеры 530х430) */
	new(MazePic, picture),
	send(MazePic, width(1440)),
	send(MazePic, height(840)),
	/* Кнопки */
	new(BtnGenerateMaze, button('Generate Maze', message(
		@prolog, generate_maze, WidthSelector?selection, HeightSelector?selection, MazePic))),
	new(BtnSolveMaze, button('Solve Maze', message(
		@prolog, solve_maze, WidthSelector?selection, HeightSelector?selection, MazePic))),
	new(BtnExit, button('Exit', message(
		MainWindow, destroy))),
	/* Группирование селекторов и кнопок */
	new(ControllerGroup, dialog_group('')),
	send(ControllerGroup, append, WidthSelector),
	send(ControllerGroup, append, HeightSelector, right),
	send(ControllerGroup, append, BtnGenerateMaze, right),
	send(ControllerGroup, append, BtnSolveMaze, right),
	send(ControllerGroup, append, BtnExit, right),
	/* Добавление элементов интерфейса в главное окно приложения */
	send_list(MainWindow, append, [ControllerGroup, MazePic]),
	/* Отрисовка главного окна приложения */
	%send(MazePic, open),
	send(MainWindow, open).



% ------------------------------ ГРАФИЧЕСКИЙ ИНТЕРФЕЙС ------------------------
%
% ------------------------------ СОЗДАНИЕ ЛАБИРИНТА ---------------------------



/* Генерация нового лабиринта */
generate_maze(Width, Height, MazePic) :-
	/* Удаление информации о клетках старого лабиринта */
	retractall(cell(_, _, _)),
	retractall(path(_, _)),
	/* Удаление изображения старого лабиринта */
	send(MazePic, clear),
	/* Размер клетки и смещение лабиринта*/
	is(CellSize, 20), is(MazeOffset, 20),
	/* Отрисовка сетки */
	forall(
		between(0, Height, H), (
		/* Абсциссы */
		is(StartX, MazeOffset),
		is(EndX, MazeOffset + Width * CellSize),
		/* Ордината */
		is(Y, MazeOffset + H * CellSize),
		/* Отрисовка горизонтальной линии сетки */
		send(MazePic, display, line(StartX, Y, EndX, Y)))
	),
	forall(
		between(0, Width, W), (
		/* Абсцисса */
		is(X, MazeOffset + W * CellSize),
		/* Ординаты */
		is(StartY, MazeOffset),
		is(EndY, MazeOffset + Height * CellSize),
		/* Отрисовка вертикальной линии сетки */
		send(MazePic, display, line(X, StartY, X, EndY)))
	),
	/* Отрисовка входа (1, 1) и выхода (Width, Height) из лабиринта */
	break_wall(1, 1, 1, MazePic),
	break_wall(Width, Height, 2, MazePic),
	/* Запись свободных клеток в базу */
	forall(
		between(1, Height, Y), (
		forall(
			between(1, Width, X), (
			assert(cell(X, Y, 0))))
		)
	),
	/* Стартовая клетка - (1, 1) */
	retract(cell(1, 1, _)),
	assert(cell(1, 1, 1)),
	is(CurrentX, 1), is(CurrentY, 1),
	/* Отрисовка путей в лабиринте */
	draw_maze(CurrentX, CurrentY, [], MazePic).
	
	

/* Отрисовка вариантов путей в лабиринте */
draw_maze(CurrentX, CurrentY, Stack, MazePic) :-
	/* Если есть свободные соседи */
	check_neighbours(CurrentX, CurrentY),
	/* Определяем следующую клетку */
	get_next_cell(CurrentX, CurrentY, NextX, NextY, Direction),
	/* Удаляем стенку между клетками */
	break_wall(CurrentX, CurrentY,  Direction, MazePic),
	/* Обновляем информацию о клетке cell(NextX, NextY) */
	retract(cell(NextX, NextY, _)),
	assert(cell(NextX, NextY, 1)),
	/* Добавляем путь из клетки cell(CurrentX, CurrentY) в клетку cell(NextX, NextY) */
	assert(path([CurrentX, CurrentY], [NextX, NextY])),
	/* Добавляем текущую клетку в стек, новую клетку делаем текущей */
	draw_maze(NextX, NextY, [cell(CurrentX, CurrentY, 1) | Stack], MazePic).

draw_maze( _, _, [cell(NextX, NextY, _) | Stack], MazePic) :-
	/* Берем клетку из стека и делаем текущей */
	draw_maze(NextX, NextY, Stack, MazePic).



/* Определение следующей клетки */
get_next_cell(CurrentX, CurrentY, NextX, NextY, Direction) :-
	repeat,
		/* Определяем направление движения: 1-влево, 2-вправо, 3-вверх, 4-вниз */
		random_between(1, 4, Direction),
		/* Определяем следующую клетку */
		next_cell(CurrentX, CurrentY, NextX, NextY, Direction),
	/* Проверяем, что следующая клетка свободна */
	while(NextX, NextY), !.

while(NextX, NextY) :-
	cell(NextX, NextY, 0), !.

while( _, _) :-
	fail.



/* Проверка, что хотя бы одна соседняя клетка - свободная */
check_neighbours(CurrentX, CurrentY) :-
	is(NextX, CurrentX - 1), is(NextY, CurrentY), cell(NextX, NextY, 0); % Левый сосед
	is(NextX, CurrentX + 1), is(NextY, CurrentY), cell(NextX, NextY, 0); % Правый сосед
	is(NextX, CurrentX), is(NextY, CurrentY - 1), cell(NextX, NextY, 0); % Верхний сосед
	is(NextX, CurrentX), is(NextY, CurrentY + 1), cell(NextX, NextY, 0). % Нижний сосед



/* Определение координат следующей клетки */
next_cell(CurrentX, CurrentY, NextX, NextY, Direction) :-
	Direction =:= 1, is(NextX, CurrentX - 1), is(NextY, CurrentY); % Левый сосед
	Direction =:= 2, is(NextX, CurrentX + 1), is(NextY, CurrentY); % Правый сосед
	Direction =:= 3, is(NextX, CurrentX), is(NextY, CurrentY - 1); % Верхний сосед
	Direction =:= 4, is(NextX, CurrentX), is(NextY, CurrentY + 1). % Нижний сосед



/* Удаление стенки между двумя клетками */
break_wall(CurrentX, CurrentY,  1, MazePic) :- % Движение влево
	is(X, CurrentX * 20), is(YU, CurrentY * 20), is(YD, YU + 20),
	new(Wall, line(X, YU, X, YD)),
	send(Wall, colour, colour(white)),
	send(MazePic, display, Wall).

break_wall(CurrentX, CurrentY,  2, MazePic) :- % Движение вправо
	is(X, CurrentX * 20 + 20), is(YU, CurrentY * 20), is(YD, YU + 20),
	new(Wall, line(X, YU, X, YD)),
	send(Wall, colour, colour(white)),
	send(MazePic, display, Wall).

break_wall(CurrentX, CurrentY,  3, MazePic) :- % Движение вверх
	is(XL, CurrentX * 20), is(XR, XL + 20), is(Y, CurrentY * 20),
	new(Wall, line(XL, Y, XR, Y)),
	send(Wall, colour, colour(white)),
	send(MazePic, display, Wall).

break_wall(CurrentX, CurrentY,  4, MazePic) :- % Движение вниз
	is(XL, CurrentX * 20), is(XR, XL + 20), is(Y, CurrentY * 20 + 20),
	new(Wall, line(XL, Y, XR, Y)),
	send(Wall, colour, colour(white)),
	send(MazePic, display, Wall).



% ------------------------------ СОЗДАНИЕ ЛАБИРИНТА ---------------------------
%
% ------------------------------ РЕШЕНИЕ ЛАБИРИНТА ----------------------------



solve_maze(Width, Height, MazePic) :- 
	/* Стартовая клетка */
	is(CurrentX, 1), is(CurrentY, 1),
	/* Клетка-финиш */
	is(LastX, Width), is(LastY, Height),
	/* Поиск пути из стартовой клетки */
	find_way([CurrentX, CurrentY], [LastX, LastY], Way),
	/* Отрисовка пути */
	draw_way(MazePic, Way).



/* Поиск пути в лабиринте */
find_way(From, To, Way) :- 
	way(From, [To], Way).



way(From, [From | Tail], [From | Tail]).

way(From, [To | Tail], Way) :-
	dif(From, To),
	path_inverse(To, Temp),
	not(member(Temp, Tail)),
	way(From, [Temp, To | Tail], Way).



path_inverse(X, Y) :- 
	path(X, Y);
	path(Y, X).



/* Отрисовка ответа-пути в лабиринте */
draw_way(MazePic, [ [X2, Y] ]) :- % Выход из лабиринта
	is(TX1, X2 * 20 + 5), is(TY1, Y * 20 + 5),
	is(TX2, TX1), is(TY2, TY1 + 10), 
	is(TX3, TX1 + 10), is(TY3, TY1 + 5), 
	draw_triangle(MazePic, TX1, TY1, TX2, TY2, TX3, TY3). 

draw_way(MazePic, [[X1, Y], [X2, Y] | Tail]) :- % Движение вправо
	X2 =:= X1 + 1, 
	is(TX1, X1 * 20 + 5), is(TY1, Y * 20 + 5),
	is(TX2, TX1), is(TY2, TY1 + 10), 
	is(TX3, TX1 + 10), is(TY3, TY1 + 5), 
	draw_triangle(MazePic, TX1, TY1, TX2, TY2, TX3, TY3),
	draw_way(MazePic, [[X2,Y] | Tail]). 

draw_way(MazePic, [[X1, Y], [X2, Y] | Tail]) :- % Движение влево
	X2 =:= X1 - 1, 
	is(TX1, X1 * 20 + 5), is(TY1, Y * 20 + 10),
	is(TX2, TX1 + 10), is(TY2, TY1 - 5), 
	is(TX3, TX1 + 10), is(TY3, TY1 + 5), 
	draw_triangle(MazePic, TX1, TY1, TX2, TY2, TX3, TY3),
	draw_way(MazePic, [[X2,Y] | Tail]). 

draw_way(MazePic, [[X, Y1], [X,Y2] | Tail]) :- % Движение вниз
	Y2 =:= Y1 + 1, 
	is(TX1, X * 20 + 5), is(TY1, Y1 * 20 + 5),
	is(TX2, TX1 + 10), is(TY2, TY1), 
	is(TX3, TX1 + 5), is(TY3, TY1 + 10), 
	draw_triangle(MazePic, TX1, TY1, TX2, TY2, TX3, TY3),
	draw_way(MazePic, [[X, Y2] | Tail]). 

draw_way(MazePic, [[X, Y1], [X, Y2] | Tail]) :- % Движение вверх
	Y2 =:= Y1 - 1, 
	is(TX1, X * 20 + 10), is(TY1, Y1 * 20 + 5),
	is(TX2, TX1 - 5), is(TY2, TY1 + 10), 
	is(TX3, TX1 + 5), is(TY3, TY1 + 10), 
	draw_triangle(MazePic, TX1, TY1, TX2, TY2, TX3, TY3),
	draw_way(MazePic, [[X, Y2] | Tail]).



/* Отрисовка треугольника-направления прохождения пути */
draw_triangle(MazePic, X1, Y1, X2, Y2, X3, Y3) :-
	new(Triangle, path),
	send_list(Triangle, append, 
		[point(X1, Y1), point(X2, Y2), point(X3, Y3), point(X1, Y1)]),
	send(Triangle, colour, colour(black)),
	send(Triangle, fill_pattern, colour(yellow)),
	send(MazePic, display, Triangle).



/* Отрисовка пути кругами
draw_way(MazePic, [[X, Y] | Tail]) :-
	is(CentreX, X * 20 + 10),
	is(CentreY, Y * 20 + 10),
	is(Diameter, 10),
	new(Mark, circle(Diameter)),
	send(Mark, colour, colour(black)),
	send(Mark, fill_pattern, colour(yellow)),
	send(MazePic, display, Mark, point(CentreX, CentreY)),
	draw_way(MazePic, Tail).
*/



% ------------------------------ РЕШЕНИЕ ЛАБИРИНТА ----------------------------


































