library("grid")
library("piecepackr")
library("rsvg")

# Book SVG from Wikimedia Commons
# Source: https://commons.wikimedia.org/wiki/File:SVG_coat_of_arms_elements_-_books.svg
# Author: User:Heralder
# License: CC0 Public Domain Dedication
book_img <- rsvg_nativeraster("data-raw/books.svg", width = 600)

green <- "#228B22"
w <- 4.5

draw_logo <- function(border = TRUE, cut = FALSE) {
	hex <- pp_shape("convex6")
	grid.newpage()
	grid.draw(hex$shape(gp = gpar(fill = green, col = "transparent")))
	if (border) {
		grid.draw(hex$mat(mat_width = 0.015, gp = gpar(fill = "black")))
	}
	if (cut) {
		pushViewport(viewport(width = unit(8 / 9, "npc"), height = unit(8 / 9, "npc")))
		grid.draw(hex$shape(gp = gpar(fill = "transparent", col = "white")))
		popViewport()
		pushViewport(viewport(width = unit(5 / 6, "npc"), height = unit(5 / 6, "npc")))
		grid.draw(hex$shape(gp = gpar(fill = "transparent", col = "white")))
		popViewport()
	}

	pushViewport(viewport(width = unit(w, "in"), height = unit(w, "in")))
	grid.raster(book_img, x = 0.52, y = 0.55, width = 0.72)
	grid.text(
		"ledger",
		x = 0.5,
		y = 0.24,
		gp = gpar(fontsize = 50, fontfamily = "TeX Gyre Heros", col = "white", fontface = 2)
	)
	popViewport()
}

svg("man/figures/logo.svg", width = w, height = w, bg = "transparent")
draw_logo(border = TRUE)
dev.off()

png("man/figures/logo.png", width = w, height = w, units = "in", res = 72, bg = "transparent")
draw_logo(border = TRUE)
dev.off()

# https://www.stickermule.com/support/full-bleed
png(
	"data-raw/sticker_with_cutline.png",
	width = 5.125,
	height = 5.125,
	units = "in",
	res = 150,
	bg = green
)
draw_logo(border = FALSE, cut = TRUE)
dev.off()

# https://www.stickermule.com/support/full-bleed
png("data-raw/sticker.png", width = 5.125, height = 5.125, units = "in", res = 150, bg = green)
draw_logo(border = FALSE, cut = FALSE)
dev.off()
