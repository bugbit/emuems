# emuems
<br>
<p>Emulador de memoria expandida EMS para 8086/8088 mediante el disco duro.</p>
<p>Lo desarrolle en el año 1994 con el turbo assembler de Borland en un PC 8088.Lo probe con los siguiente programas: Turbo Debug, Autocad y algunos más funcionado correctamente solo con la única excepción del letargo del disco duro</p>
<br>
<p>Para iniciarlo debéis indicar por parámetros la ruta donde se guardan los archivos de disco y el número de MB de memoria a emular, por ejemplo:</p>
<br>
<p>EMUEMS C:\ 1 </p>
<br>
<p>Con esto generará los archivos temporales en la raíz de la C:. Dichos archivos tienen nombre:</p>
<br>
<p>EMS$0000.$$$</p>
<br>
<p>Donde el 0000 es un número que se va incrementando.
El emulador ocupa en memoria 66 KB, 2 KB de ellos es el propio emulador y los 64 kb restantes los utiliza precisamente para mapear la EMS.</p>
