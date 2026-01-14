# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# db/seeds.rb

tiles = [
  { name: "3 MOONS ITEMS", image_path: "" },
  { name: "3 BARROWS ITEMS", image_path: "" },
  { name: "3 DKS RINGS", image_path: "" },
  { name: "GO BACK 2 TILES", image_path: "" },
  { name: "CREATE & POST OSRS MEME IN DISC", image_path: "" },
  { name: "COMPLETE TWINFLAME STAFF", image_path: "" },
  { name: "ZENYTE SHARD", image_path: "" },
  { name: "ZULRAH UNIQUE", image_path: "" },
  { name: "ANY ABYSSAL DYE", image_path: "" },
  { name: "ROLL AGAIN", image_path: "" },
  { name: "DRAGON PICKAXE", image_path: "" },
  { name: "TOA PURPLE", image_path: "" },
  { name: "ANY BOSS JAR", image_path: "" },
  { name: "GO BACK 3 TILES", image_path: "" },
  { name: "INKY PAINT OR BACK 3 TILES", image_path: "" },
  { name: "COMPLETE ODIUM WARD", image_path: "" },
  { name: "DRAGON HUNTER WAND", image_path: "" },
  { name: "CoX PURPLE", image_path: "" },
  { name: "CHECKPOINT! COLLECT 3M", image_path: "" },
  { name: "ANY OATHPLATE PIECE", image_path: "" },
  { name: "BROKEN DRAGON HOOK OR BACK 3 SPACES", image_path: "" },
  { name: "GO FORWARD 2 TILES", image_path: "" },
  { name: "MYSTERY", image_path: "" },
  { name: "ANY DOOM UNIQUE", image_path: "" },
  { name: "GO BACK 2 TILES", image_path: "" },
  { name: "ORNAMENT KIT (ELITE/MASTER CASKET)", image_path: "" },
  { name: "ENHANCED CRYSTAL WEAPON SEED", image_path: "" },
  { name: "ANY COMPLETE GODSWORD", image_path: "" },
  { name: "ANY VIRTUS PIECE", image_path: "" },
  { name: "COMPLETE VOIDWAKER", image_path: "" },
  { name: "NIGHTMARE ORB", image_path: "" },
  { name: "ToB PURPLE", image_path: "" },
  { name: "ANY SIGIL FROM CORP", image_path: "" },
  { name: "FINISH", image_path: "" }
]


Tile.destroy_all

tiles.each do |t|
  Tile.create!(name: t[:name], image_path: t[:image_path])
end

puts "Seeded #{Tile.count} tiles 🧩"
