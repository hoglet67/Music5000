#!/bin/bash

BOARD=Music5000

mv $BOARD-B.Cu.gbl      $BOARD.gbl
mv $BOARD-B.Mask.gbs    $BOARD.gbs
mv $BOARD-B.SilkS.gbo   $BOARD.gbo
mv $BOARD.drl           $BOARD.xln
mv $BOARD-Edge.Cuts.gm1 $BOARD.gko
mv $BOARD-F.Cu.gtl      $BOARD.gtl
mv $BOARD-F.Mask.gts    $BOARD.gts
mv $BOARD-F.SilkS.gto   $BOARD.gto

rm -f manufacturing.zip
zip -qr manufacturing.zip $BOARD.*
