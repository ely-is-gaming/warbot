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
  { name: "START", modifier: 0, conditional_modifier: 0, image_path: "https://media.discordapp.net/attachments/1310485470047768606/1454585208954290303/image.png?ex=69695a8a&is=6968090a&hm=ebd120f721a5878351266f833fd1a20c1de999472117d6f8a32811ca490dced9&=&format=webp&quality=lossless&width=539&height=472" },
  { name: "3 MOONS ITEMS", modifier: 0, conditional_modifier: 0, image_path: "https://oldschool.runescape.wiki/images/thumb/Lunar_Chest_%28closed%29.png/640px-Lunar_Chest_%28closed%29.png?19bbc" },
  { name: "3 BARROWS ITEMS", modifier: 0, conditional_modifier: 0, image_path: "https://oldschool.runescape.wiki/images/thumb/Barrows_minigame.png/300px-Barrows_minigame.png?f7aaf" },
  { name: "3 DKS RINGS", modifier: 0, conditional_modifier: 0, image_path: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSBkWFqSFk0MYcIsMhhwk5xnShkbCpuxN0guQ&s" },
  { name: "GO BACK 2 TILES", modifier: -2, conditional_modifier: 0, image_path: "https://cdn-icons-png.freepik.com/256/10393/10393160.png" },
  { name: "CREATE & POST OSRS MEME IN DISC", modifier: 0, conditional_modifier: 0, image_path: "https://preview.redd.it/can-anyone-give-me-your-best-meme-images-like-this-classic-v0-25nq3oa4y9df1.jpeg?width=640&crop=smart&auto=webp&s=413b07373e598535fc75d51ccddead0c306302e5" },
  { name: "COMPLETE TWINFLAME STAFF", modifier: 0, conditional_modifier: 0, image_path: "https://media.discordapp.net/attachments/1309805953377505314/1438340772284862605/image.png?ex=6968ec7b&is=69679afb&hm=dc53b773090a77f50ff31aa6a79b27e62f36a25e98bab958dbe432c9d70f5ce2&=&format=webp&quality=lossless&width=1274&height=1260" },
  { name: "ZENYTE SHARD", modifier: 0, conditional_modifier: 0, image_path: "https://oldschool.runescape.wiki/images/Zenyte_shard.png?8abb8" },
  { name: "ZULRAH UNIQUE", modifier: 0, conditional_modifier: 0, image_path: "https://oldschool.runescape.wiki/images/Venom_cloud.png?0bae0" },
  { name: "ANY ABYSSAL DYE", modifier: 0, conditional_modifier: 0, image_path: "https://oldschool.runescape.wiki/images/thumb/Guardians_of_the_Rift_Launch_%281%29.jpg/400px-Guardians_of_the_Rift_Launch_%281%29.jpg?1e0f7" },
  { name: "ROLL AGAIN", modifier: 0, conditional_modifier: 0, image_path: "https://i1.sndcdn.com/artworks-6QKBx2pGfwKnMHVa-ZLpPGA-t500x500.jpg" },
  { name: "DRAGON PICKAXE", modifier: 0, conditional_modifier: 0, image_path: "https://oldschool.runescape.wiki/images/Player_killing.gif?613f9" },
  { name: "TOA PURPLE", modifier: 0, conditional_modifier: 0, image_path: "https://media.discordapp.net/attachments/1310485470047768606/1427852646907383919/image.png?ex=69685767&is=696705e7&hm=ee09e6abc99cb9799f64f46c9aaf3079d5676e90ceb7774ef57d599529ef1348&=&format=webp&quality=lossless&width=1791&height=1115" },
  { name: "ANY BOSS JAR", modifier: 0, conditional_modifier: 0, image_path: "https://oldschool.runescape.wiki/images/thumb/Grotesque_Guardians_display.png/400px-Grotesque_Guardians_display.png?17400" },
  { name: "GO BACK 3 TILES", modifier: -3, conditional_modifier: 0, image_path: "https://cdn-icons-png.flaticon.com/512/854/854977.png" },
  { name: "INKY PAINT OR BACK 3 TILES", modifier: 0, conditional_modifier: -3, image_path: "https://oldschool.runescape.wiki/images/thumb/Inky_paint_detail.png/130px-Inky_paint_detail.png?11afa" },
  { name: "COMPLETE ODIUM WARD", modifier: 0, conditional_modifier: 0, image_path: "https://oldschool.runescape.wiki/images/Odium_ward.png?b959a" },
  { name: "DRAGON HUNTER WAND", modifier: 0, conditional_modifier: 0, image_path: "https://oldschool.runescape.wiki/images/thumb/Dragon_hunter_wand_detail.png/640px-Dragon_hunter_wand_detail.png?a3e16" },
  { name: "CoX PURPLE", modifier: 0, conditional_modifier: 0, image_path: "https://media.discordapp.net/attachments/1310485470047768606/1426614573615808553/Screenshot_2025-10-11_114224.png?ex=6967cadb&is=6966795b&hm=eae2cd949d0ad0305b6b169815c5c245b809a416a96a8356fb33b8b6df9b426e&=&format=webp&quality=lossless&width=1318&height=602" },
  { name: "CHECKPOINT! COLLECT 3M", modifier: 0, conditional_modifier: 0, image_path: "https://oldschool.runescape.wiki/images/thumb/Coins_detail.png/640px-Coins_detail.png?404bc" },
  { name: "ANY OATHPLATE PIECE", modifier: 0, conditional_modifier: 0, image_path: "https://oldschool.runescape.wiki/images/Yama_chathead.png?e940b" },
  { name: "BROKEN DRAGON HOOK OR BACK 3 SPACES", modifier: 0, conditional_modifier: -3, image_path: "https://oldschool.runescape.wiki/images/Broken_dragon_hook.png?afec5"},
  { name: "GO FORWARD 2 TILES", modifier: 2, conditional_modifier: 0, image_path: "https://cdn-icons-png.flaticon.com/512/854/854977.png" },
  { name: "MYSTERY", modifier: 0, conditional_modifier: 0, image_path: "https://oldschool.runescape.wiki/images/thumb/Mystery_box_detail.png/1200px-Mystery_box_detail.png?0e275" },
  { name: "ANY DOOM UNIQUE", modifier: 0, conditional_modifier: 0, image_path: "https://oldschool.runescape.wiki/images/Fighting_the_Doom_of_Mokhaiotl.png?165b2" },
  { name: "GO BACK 2 TILES", modifier: -2, conditional_modifier: 0, image_path: "https://cdn-icons-png.flaticon.com/512/854/854977.png" },
  { name: "ORNAMENT KIT (ELITE/MASTER CASKET)", modifier: 0, conditional_modifier: 0, image_path: "https://oldschool.runescape.wiki/images/Necklace_of_anguish_%28or%29_original_model.jpg?1f6ef" },
  { name: "ENHANCED CRYSTAL WEAPON SEED", modifier: 0, conditional_modifier: 0, image_path: "https://oldschool.runescape.wiki/images/thumb/Fighting_Corrupted_Hunllef.png/250px-Fighting_Corrupted_Hunllef.png?8e2d6" },
  { name: "ANY COMPLETE GODSWORD", modifier: 0, conditional_modifier: 0, image_path: "https://oldschool.runescape.wiki/images/thumb/Armadyl_godsword_detail.png/1200px-Armadyl_godsword_detail.png?f2566" },
  { name: "ANY VIRTUS PIECE", modifier: 0, conditional_modifier: 0, image_path: "https://i.redd.it/can-we-please-change-the-look-of-the-virtus-robe-set-v0-4yg4nwoa3kcb1.jpg?width=472&format=pjpg&auto=webp&s=6b0b877e90b6dacac49db663d867b0848366df6b" },
  { name: "COMPLETE VOIDWAKER", modifier: 0, conditional_modifier: 0, image_path: "https://oldschool.runescape.wiki/images/Disrupt.gif?9ec07" },
  { name: "NIGHTMARE ORB", modifier: 0, conditional_modifier: 0, image_path: "https://oldschool.runescape.wiki/images/thumb/Fighting_The_Nightmare.png/300px-Fighting_The_Nightmare.png?152f0" },
  { name: "ToB PURPLE", modifier: 0, conditional_modifier: 0, image_path: "https://media.discordapp.net/attachments/1310485470047768606/1429309397011664987/image.png?ex=69685e1b&is=69670c9b&hm=9ab8747477ca84588e742b114c2777b402fa8343ae1f669191ba9053f98b3a41&=&format=webp&quality=lossless&width=1416&height=1389" },
  { name: "ANY SIGIL FROM CORP", modifier: 0, conditional_modifier: 0, image_path: "https://media.discordapp.net/attachments/1310485470047768606/1437192380003520512/image.png?ex=69680ab5&is=6966b935&hm=941ff5456aff1fe523b42a9d8e83eba4c59eb90c1dd925212bf1d57a7661256a&=&format=webp&quality=lossless&width=1579&height=1174" },
  { name: "FINISH", modifier: 0, conditional_modifier: 0, image_path: "https://media.discordapp.net/attachments/1309808330822385675/1461010044681322656/content.png?ex=6968ff22&is=6967ada2&hm=31610d85bceed6d3069ab68fd20631eeb1a49ca0f79aa7114dca1e1ae9cfadb3&=&format=webp&quality=lossless&width=315&height=472" }
]


Tile.destroy_all

tiles.each do |t|
  Tile.create!(name: t[:name], image_path: t[:image_path], modifier: t[:modifier], conditional_modifier: t[:conditional_modifier])
end

puts "Seeded #{Tile.count} tiles 🧩"
