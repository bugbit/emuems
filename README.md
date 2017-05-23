# emuems
 un simple pc 8088/8086 se puede disponer de memoria ems mediante la emulación con archivos de disco.	
		
<p>Emulador memoria expandida EMS para core PC/XT
Mensaje22 May 2017, 10:12Evidentemente no va a ir tan rápido como una memoria física, pero para usar algunos programas puede servir.
Es un programa del año 1994, en su momento se probó con varios programas de la época (creo recordar que con Turbo Debug, Autocad y algunos más) y funcionaba correctamente. Yo lo he probado recientemente desde dosbox, con mi viejo emulador ZXSpectr de ms-dos (que puede usar EMS), y funciona. Ni lo he probado en una máquina física con MS-DOS ahora ni con el core pc/xt del zxuno, pero debería funcionar.</p>
<br>
<p>Está distribuido mediante licencia GNU GPL v3, tiene el código fuente y el binario disponible.</p>
<br>
<p>Al iniciarlo debéis indicar por parámetros la ruta donde se guardan los archivos de disco y el número de MB de memoria a emular, por ejemplo:</p>
<br>
<p>EMUEMS C:\ 1 </p>
<br>
<p>Con esto generará los archivos temporales en la raíz de la C:. Dichos archivos tienen nombre:</p>
<br>
<p>EMS$0000.$$$</p>
<br>
<p>Donde el 0000 es un número que se va incrementando.
El emulador ocupa en memoria 66 KB, 2 KB de ellos es el propio emulador y los 64 kb restantes los utiliza precisamente para mapear la EMS.</p>
