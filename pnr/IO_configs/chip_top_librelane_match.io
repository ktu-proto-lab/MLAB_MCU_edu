(globals
    version = 3
    io_order = default
)
(iopad
	(topleft
	(inst name="CornerCell1" cell=sg13g2_Corner offset=0 orientation=r180 place_status=placed )
	)
    (top
	(inst  name="\bidirs[10].bidir_pad" 		offset=255  	place_status=placed)
	(inst  name="\bidirs[11].bidir_pad" 		offset=410 	place_status=placed)
	(inst  name="iovdd_pads\\[0\\].iovdd_pad" 	offset=565  	place_status=placed)
	(inst  name="iovdd_pads\\[1\\].iovdd_pad" 	offset=720  	place_status=placed)
	(inst  name="iovdd_pads\\[2\\].iovdd_pad" 	offset=875  	place_status=placed)
	(inst  name="iovss_pads\\[0\\].iovss_pad" 	offset=1025  place_status=placed)
	(inst  name="iovss_pads\\[1\\].iovss_pad" 	offset=1175  place_status=placed)
    )
	(topright
	(inst name="CornerCell2" cell=sg13g2_Corner offset=0 orientation=r180 place_status=placed )
	)
    (right
	# PAD_NORTH reversed (LibreLane north = east→west; Innovus top offset increases west→east)
	(inst  name="\bidirs[4].bidir_pad" offset=277  	place_status=placed)
	(inst  name="\bidirs[5].bidir_pad" offset=454  	place_status=placed)
	(inst  name="\bidirs[6].bidir_pad" offset=632  	place_status=placed)
	(inst  name="\bidirs[7].bidir_pad" offset=808  	place_status=placed)
	(inst  name="\bidirs[8].bidir_pad" offset=985  	place_status=placed)
	(inst  name="\bidirs[9].bidir_pad" offset=1162 	place_status=placed)
    )
	(bottomright
	(inst name="CornerCell3" cell=sg13g2_Corner offset=0 orientation=r180 place_status=placed )
	)
    (bottom
	# PAD_NORTH reversed (LibreLane north = east→west; Innovus top offset increases west→east)
	(inst  name="clk_pad" 				offset=277  	place_status=placed)
	(inst  name="rst_n_pad" 			offset=454  	place_status=placed)
	(inst  name="\bidirs[0].bidir_pad" 	offset=632  	place_status=placed)
	(inst  name="\bidirs[1].bidir_pad" 	offset=808  	place_status=placed)
	(inst  name="\bidirs[2].bidir_pad" 	offset=985  	place_status=placed)
	(inst  name="\bidirs[3].bidir_pad" 	offset=1162  	place_status=placed)
    )
	(bottomleft
	(inst name="CornerCell4" cell=sg13g2_Corner offset=0 orientation=r180 place_status=placed )
	)
    (left
	# PAD_NORTH reversed (LibreLane north = east→west; Innovus top offset increases west→east)
	(inst  name="iovss_pads\\[2\\].iovss_pad" 		offset=277  	place_status=placed)
	(inst  name="iovss_pads\\[3\\].iovss_pad"		offset=454  	place_status=placed)
	(inst  name="vdd_pads\\[0\\].vdd_pad" 			offset=632  	place_status=placed)
	(inst  name="vdd_pads\\[1\\].vdd_pad" 			offset=808  	place_status=placed)
	(inst  name="vss_pads\\[0\\].vss_pad" 			offset=985  	place_status=placed)
	(inst  name="vss_pads\\[1\\].vss_pad" 			offset=1162  	place_status=placed)
	)
)