# World 2 dialogue scripts (for Block 12)

Scripts of the Director (**Her Mosso**) for World 2, *Segundo semestre* (Biblioteca Central). They follow plan section 6.4 and the same rules as World 1: 4 to 12 lines per conversation, school humor, fictional teachers only (never real names or faces).

Block 12 turns each block below into a `DialogueData` file in `data/dialogues/` (one `DialogueLine` per line, `expression` from the column, `show_card` / `show_enemy` when the line presents something) and links it from the `LevelData` / `WorldData` field in the heading. The text is in Spanish because it is shown in the game. The whole team reviews it before it goes in.

## Story so far

World 1 ends with a clue: the Examen Final drops a stamp, *"Biblioteca Central. Préstamo vencido"*. The pending tasks do not only come from the Archivo Muerto (the basement where undelivered homework wakes up every semester). In World 2 the player follows the clue to the library, finds out that the overdue books are the ones marching, and learns that someone signs every "préstamo": the first hint of **El Sínodo**, the final boss of semester 8.

## `w2_intro` → `world_2.tres` · `intro_dialogue`

| Expression | Text | Presents |
|---|---|---|
| feliz | ¡Segundo semestre! Seguimos la pista del sello: bienvenido a la Biblioteca Central. | |
| normal | Aquí todo es en equipo: proyectos, entregas, exposiciones… y gente que nunca llega. | |
| preocupado | Y mira esos estantes: faltan cientos de libros. Todos con préstamo vencido. | |
| serio | Si esos libros despertaron como las tareas, van a venir por ti. Prepárate. | |
| feliz | Te tengo cartas nuevas. Empieza por «Inscripciones». | |

## `w2_l1_intro` → `w2_l1.tres` (Inscripciones) · `intro_dialogue`

| Expression | Text | Presents |
|---|---|---|
| feliz | Para empezar, te doy el USB: barato, rápido de recargar y siempre se pierde. | card: USB |
| normal | No aguanta tanto como el Firewall, pero sale en cualquier apuro. | |
| sorprendido | ¡Ahí está! La Bibliografía: carga una pila de libros que absorbe el daño. | enemy: La Bibliografía |
| serio | Cuando se le caen los libros, todavía queda alguien debajo. No bajes la guardia. | |

## `w2_l2_intro` → `w2_l2.tres` (La biblioteca a las 7 a. m.) · `intro_dialogue`

| Expression | Text | Presents |
|---|---|---|
| normal | Siete de la mañana y ya no hay mesas. ¿A qué hora llega esta gente? | |
| feliz | Te presento la Calculadora científica: dispara el doble de rápido. | card: Calculadora científica |
| normal | Cada tiro hace menos daño, pero no se cansa. Como tú en época de exámenes. | |
| sorprendido | Encontré otro sello en un libro: «Préstamo autorizado por… S.». Solo una letra. | |

## `w2_l3_intro` → `w2_l3.tres` (Equipo de cuatro) · `intro_dialogue`

| Expression | Text | Presents |
|---|---|---|
| preocupado | Ay, no. El Proyecto en Equipo. | enemy: El Proyecto en Equipo |
| normal | Cuando lo derrotas, se divide en dos: los que no trabajaron. | |
| serio | No te confíes al verlo caer: todavía faltan dos, y ninguno trae su parte. | |
| feliz | Tranquilo, aquí tú sí vas a hacer tu parte. Y la de ellos, como siempre. | |

## `w2_l4_intro` → `w2_l4.tres` (Llegando tarde) · `intro_dialogue`

| Expression | Text | Presents |
|---|---|---|
| sorprendido | ¡El Retardo! Llega tarde a todo… menos a saltarse a tu primer defensor. | enemy: El Retardo |
| normal | Para eso te doy el Router lento: su señal deja a los enemigos con lag. | card: Router lento |
| feliz | Los frena a la mitad durante tres segundos. Es el wifi de la escuela, pero a tu favor. | |
| serio | Pon algo barato delante, para que el Retardo salte sobre eso y no sobre tus Laptops. | |

## `w2_l5_intro` → `w2_l5.tres` (Semana de entregas) · `intro_dialogue`

| Expression | Text | Presents |
|---|---|---|
| serio | Semana de entregas: todo para el viernes a las 23:59. | |
| feliz | Te doy mi carta favorita: Ctrl+Z. Borra a los enemigos de un área de 3 × 3. | card: Ctrl+Z |
| normal | Se usa una vez y desaparece. Ojalá funcionara igual con mis correos. | |
| preocupado | Dicen que quien firmó los préstamos está esperando al final del semestre… | |

## `w2_l6_intro` → `w2_l6.tres` (El proyecto final) · `intro_dialogue`

| Expression | Text | Presents |
|---|---|---|
| serio | Llegó la entrega del proyecto final. | |
| sorprendido | ¡La Profesora del Proyecto Final! Ella autorizaba los préstamos… ¿o solo los firmaba por alguien más? | enemy: La Profesora del Proyecto Final |
| preocupado | Llama a Proyectos en Equipo. A la mitad de su vida se acelera y empieza a llamar Bibliografías. | |
| normal | Guarda tu Ctrl+Z para cuando se te junten. Y no olvides los extraordinarios. | |
| feliz | Llegaste hasta aquí. ¡Entrega ese proyecto! | |

## `w2_l6_outro` → `w2_l6.tres` · `outro_dialogue`

| Expression | Text | Presents |
|---|---|---|
| orgulloso | ¡Proyecto entregado! Y a tiempo. Eso no lo había visto nunca. | |
| sorprendido | La Profesora dejó caer su libreta. Tiene una lista: ocho semestres, ocho nombres… | |
| serio | Y al final, tres firmas y una palabra: «Sínodo». | |
| preocupado | No sé qué sea, pero nos está esperando al final de la carrera. | |

## `w2_outro` → `world_2.tres` · `outro_dialogue`

| Expression | Text | Presents |
|---|---|---|
| orgulloso | ¡Segundo semestre aprobado! Ya sobreviviste a un proyecto en equipo. Eres leyenda. | |
| feliz | Revisa tu Expediente: ya tienes una buena colección. | |
| normal | La libreta dice que el tercer semestre es en el Estadio Wilfrido Massieu. | |
| serio | Ahí los exámenes departamentales llegan por montones. Ve calentando. ¡Huélum! | |

## Notes for Block 12

- `w2_l1.tres`: set `featured_enemy` = La Bibliografía. `w2_l3`: El Proyecto en Equipo. `w2_l4`: El Retardo. `w2_l6`: the boss.
- `reward_card` is optional in World 2: every new card is already presented at the start of its level.
- `w2_l6_outro` goes in `outro_dialogue` of `w2_l6.tres`, like `w1_l6_outro` in World 1.
- Each new card and enemy needs its `description` (it is shown in "¡Nueva carta!" and in the Expediente).
