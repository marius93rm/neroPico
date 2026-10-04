# Verifica della revisione

Eseguita il **4 ottobre 2026** in Chromium con il runtime ufficiale **PICO-8 Education Edition**. Il file sottoposto alla prova è stato generato da `src/game.lua` e `assets/sprites.txt`.

La cartuccia precedente mostrava un errore di sintassi nella prima esecuzione effettuata in questo ambiente. La nuova cartuccia supera avvio e percorso completo.

## Esito

| Prova | Risultato |
| --- | --- |
| Caricamento, titolo e avvio con Z | Superata |
| Camminata e collisione con i rampicanti | Superata |
| Freccia tenuta premuta per oltre la finestra del doppio tocco | Nessun dash involontario |
| Morso sui rampicanti | Ostacolo conservato |
| Graffio sui rampicanti | Ostacolo aperto |
| Salto a pressione prolungata | Piedi a `y=83` dal terreno a `y=112` |
| Graffio sulla cassa | Ostacolo conservato |
| Morso durante il salto, sopra la cassa | Nessun colpo fuori dall'area verticale |
| Morso sulla cassa da terra | Ostacolo aperto |
| Graffio sul cartone | Ostacolo conservato |
| Dash con doppio tocco sul cartone | Ostacolo aperto |
| Recupero del nastro | Schermata finale |
| Riavvio | Posizione iniziale e tre ostacoli ripristinati |
| Generatore dell'atlante | Nessuna riga irregolare o sovrapposizione |

`tools/verify_cart.cjs` crea una copia temporanea con telemetria GPIO per osservare gli stati durante la prova. Il file distribuito non contiene questa strumentazione. Le immagini `title.png`, `preview.png`, `scratch.png`, `dash.png` e `finish.png` provengono dal canvas del runtime, ingrandite a 512×512 senza interpolazione.

## Limiti della prova

La verifica riguarda la versione browser ufficiale e il percorso del cortile. Non è stata eseguita la versione desktop commerciale, né una prova con gamepad. Le schermate mostrano fotogrammi reali; non misurano la fluidità percepita o il bilanciamento degli effetti sonori.
