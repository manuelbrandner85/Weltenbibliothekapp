#!/usr/bin/env python3
"""Build 50 RV-Targets for ursprung Remote Viewing trainer."""
import json, os

def sql_str(s):
    if s is None: return 'NULL'
    return "'" + str(s).replace("'", "''") + "'"
def sql_array(items):
    if not items: return "ARRAY[]::TEXT[]"
    return "ARRAY[" + ",".join(sql_str(x) for x in items) + "]::TEXT[]"

# (code, name, category, description, image_url, coords, difficulty, key_features)
TARGETS = [
    ("7294","Pyramiden von Gizeh","monument","Die Großen Pyramiden auf dem Gizeh-Plateau bei Kairo, Ägypten. Steinerne Konstruktionen aus massiven Blöcken, dreieckig-pyramidale Form, hellbeige bis sandfarben, in trockener Wüstenlandschaft.","https://upload.wikimedia.org/wikipedia/commons/e/e3/Kheops-Pyramid.jpg","29.9792°N, 31.1342°E",2,["dreieckig","stein","wüste","monumental","hell","heiß"]),
    ("3817","Niagarafälle","nature","Massive Wasserfälle an der Grenze USA-Kanada. Tosendes Wasser, dichter Nebel, weißer Schaum, Hufeisen-Form, weite Flussbreite, kalt-feuchte Atmosphäre.","https://upload.wikimedia.org/wikipedia/commons/0/0d/3Falls_Niagara.jpg","43.0962°N, 79.0377°W",2,["wasser","tosend","nebel","weiß","fließend","kalt","laut"]),
    ("5521","Eiffelturm","monument","Eiserner Gitterturm in Paris. Schmale aufsteigende Struktur, dunkelbraun-eisen, vier Beine die zu einem Punkt zusammenlaufen, urbane Umgebung.","https://upload.wikimedia.org/wikipedia/commons/a/a8/Tour_Eiffel_Wikimedia_Commons.jpg","48.8584°N, 2.2945°E",2,["metall","aufsteigend","gitter","urban","schmal","hoch"]),
    ("8403","Sahara-Düne","nature","Große Sandwüste mit endlosen Dünen. Welliger Sand, orange-rote Töne, heiße Trockenheit, blauer Himmel, keine Vegetation, weite Stille.","https://upload.wikimedia.org/wikipedia/commons/2/2d/Sahara_satellite_hires.jpg","23.4162°N, 25.6628°E",1,["sand","wüste","heiß","orange","welle","trocken","leer"]),
    ("1947","Stonehenge","monument","Prähistorischer Steinkreis in England. Massive vertikale Steine in Kreisform, grau-grünlich, grünes Gras, neblige Atmosphäre, mystisch.","https://upload.wikimedia.org/wikipedia/commons/1/10/Stonehenge2007_07_30.jpg","51.1789°N, 1.8262°W",2,["stein","kreis","alt","grau","mystisch","kalt"]),
    ("6320","Christusstatue Rio","monument","Riesige Christusstatue auf dem Corcovado-Berg in Rio de Janeiro. Weiße Steinfigur mit ausgebreiteten Armen, hoch oben auf einem Berg, Stadtansicht im Hintergrund.","https://upload.wikimedia.org/wikipedia/commons/f/f1/Christ_on_Corcovado_mountain.JPG","22.9519°S, 43.2105°W",3,["statue","weiß","arme","berg","hoch","religiös"]),
    ("4185","Großer Salzsee","nature","Salzsee in Utah, USA. Reflektierende weiße Salzkrusten, türkisblaues Wasser, flache Ufer, Bergketten in der Ferne, mineralischer Geruch.","https://upload.wikimedia.org/wikipedia/commons/a/aa/Great_Salt_Lake_ISS052.jpg","41.1167°N, 112.4833°W",3,["wasser","salz","weiß","türkis","flach","reflektion"]),
    ("9162","Vulkan Vesuv","nature","Aktiver Vulkan in Italien bei Neapel. Kegelförmiger Berg, dunkelgrau, leicht rauchend, Krater an der Spitze, Bucht und Stadt im Tal.","https://upload.wikimedia.org/wikipedia/commons/f/f0/Vesuvius_from_Pompeii_%28hires_version_2_scaled%29.png","40.8210°N, 14.4262°E",3,["berg","vulkan","kegel","grau","rauch","heiß","krater"]),
    ("2756","Kreml Moskau","building","Festungsanlage im Herzen von Moskau. Rote Backsteinmauern, goldene Zwiebeltürme, mehrere Kuppelkirchen, urbane Umgebung, kalt.","https://upload.wikimedia.org/wikipedia/commons/4/49/Moscow_Kremlin_from_Kamenny_bridge.jpg","55.7520°N, 37.6175°E",3,["festung","rot","gold","kuppel","kalt","monumental"]),
    ("5078","Taj Mahal","monument","Weißes Marmormausoleum in Indien. Symmetrische Kuppelarchitektur, vier Minarette, Reflexionsbecken, makellos weiß, ornamental.","https://upload.wikimedia.org/wikipedia/commons/1/1d/Taj_Mahal_%28Edited%29.jpeg","27.1751°N, 78.0421°E",2,["weiß","kuppel","symmetrisch","marmor","wasser","prächtig"]),
    ("3641","Mount Everest","nature","Höchster Berg der Welt im Himalaya. Massiver schneebedeckter Gipfel, weiß-grau, extreme Höhe, dünne Luft, eiskalt, schroff.","https://upload.wikimedia.org/wikipedia/commons/c/c6/Mount_Everest_as_seen_from_Drukair2_PLW_edit.jpg","27.9881°N, 86.9250°E",2,["berg","schnee","weiß","kalt","hoch","schroff"]),
    ("8294","Großer Korallenriff","nature","Größtes Korallenriffsystem der Welt vor Australien. Bunte Korallen, türkises Meer, tropische Fische, warmes Wasser, flach.","https://upload.wikimedia.org/wikipedia/commons/2/26/GreatBarrierReef-EO.JPG","18.2871°S, 147.6992°E",4,["wasser","bunt","tropisch","fisch","warm","türkis"]),
    ("1503","Kolosseum Rom","monument","Antikes römisches Amphitheater. Kreisförmiger Steinbau mit Bögen, beige-braun, teilweise zerstört, urbane Umgebung in Rom.","https://upload.wikimedia.org/wikipedia/commons/d/de/Colosseum_in_Rome%2C_Italy_-_April_2007.jpg","41.8902°N, 12.4922°E",2,["stein","rund","alt","bögen","beige","monumental"]),
    ("6938","Sydney Opera","building","Opernhaus mit segelförmigen weißen Dachschalen am Hafen von Sydney. Modern, weiß glänzend, am Wasser, ikonisch.","https://upload.wikimedia.org/wikipedia/commons/4/47/Sydney_Opera_House_-_Dec_2008.jpg","33.8568°S, 151.2153°E",3,["weiß","segel","modern","wasser","geschwungen"]),
    ("4729","Sphinx von Gizeh","monument","Riesige steinerne Löwenstatue mit Menschenkopf bei den Pyramiden. Sandstein, beige, halb verwittert, sitzend, blickt nach Osten.","https://upload.wikimedia.org/wikipedia/commons/1/12/Great_Sphinx_of_Giza_-_20080716a.jpg","29.9753°N, 31.1376°E",3,["stein","tier","mensch","beige","sand","alt"]),
    ("7185","Machu Picchu","monument","Inka-Ruinen hoch in den peruanischen Anden. Steinmauern, terrassiert, grüne Berge, Nebel, Höhenlage.","https://upload.wikimedia.org/wikipedia/commons/e/eb/Machu_Picchu%2C_Peru.jpg","13.1631°S, 72.5450°W",3,["stein","berg","alt","grün","terrassen","hoch"]),
    ("2839","Polarlichter","nature","Aurora Borealis am nördlichen Himmel. Grüne und violette Lichtbänder, tanzend, am Nachthimmel, eiskalte Polarregion.","https://upload.wikimedia.org/wikipedia/commons/3/30/Polarlicht_2.jpg","69.6492°N, 18.9553°E",4,["licht","grün","violett","nacht","kalt","tanzend"]),
    ("5417","Great Wall China","monument","Chinesische Mauer auf Bergrücken. Lange Steinmauer mit Wachtürmen, beige-grau, schlängelnd, weite Landschaft.","https://upload.wikimedia.org/wikipedia/commons/2/25/The_Great_Wall_of_China_at_Jinshanling-edit.jpg","40.4319°N, 116.5704°E",2,["mauer","stein","lang","berg","alt"]),
    ("9183","Antarktis Eis","nature","Endlose Eisfläche der Antarktis. Weiß, blau-schimmernd, Gletscher, Eisberge, extreme Kälte, leere Weite.","https://upload.wikimedia.org/wikipedia/commons/5/57/Antarctic_Mountains.jpg","82.8628°S, 135.0000°E",2,["eis","weiß","kalt","leer","blau","weit"]),
    ("3274","Burj Khalifa","building","Höchstes Gebäude der Welt in Dubai. Schmal aufsteigender silberner Turm, modern, urban, Wüste in der Ferne.","https://upload.wikimedia.org/wikipedia/commons/b/b3/Burj_Khalifa.jpg","25.1972°N, 55.2744°E",3,["turm","hoch","silber","modern","wüste"]),
    ("6051","Amazonas Regenwald","nature","Dichter tropischer Regenwald in Südamerika. Dunkelgrün, feucht, riesige Bäume, Lianen, mäandernder Fluss, warm.","https://upload.wikimedia.org/wikipedia/commons/c/cf/Amazonia_2007_-_Carlos-Vinicius-Caro.jpg","3.4653°S, 62.2159°W",3,["grün","wald","feucht","warm","dicht","fluss"]),
    ("4892","Easter Island Moai","monument","Geheimnisvolle Steinfiguren auf den Osterinseln. Große menschenähnliche Köpfe aus Stein, in Reihen, isolierte Pazifikinsel.","https://upload.wikimedia.org/wikipedia/commons/a/ae/Moai_Rano_raraku.jpg","27.1127°S, 109.3497°W",4,["stein","kopf","figur","insel","alt","mystisch"]),
    ("8615","Death Valley","nature","Heißestes Tal in Kalifornien. Salzpfannen, Sanddünen, rissiger Boden, brennende Hitze, kahl, beige-weiß.","https://upload.wikimedia.org/wikipedia/commons/9/9a/DeathValleySandDune.jpg","36.5054°N, 116.7986°W",3,["heiß","wüste","trocken","weiß","beige","leer"]),
    ("1726","Petra Jordanien","monument","Rosa-Felsenstadt in Jordanien. In Sandstein gehauene Fassaden, rötlich-orange Töne, Schlucht, antike Architektur.","https://upload.wikimedia.org/wikipedia/commons/0/0f/Treasury_of_Petra%2C_Jordan_at_night.jpg","30.3285°N, 35.4444°E",3,["stein","rot","fels","schlucht","alt","schmal"]),
    ("5390","Kreidefelsen Dover","nature","Weiße Kreidefelsen an der englischen Südküste. Steile weiße Klippen, blaues Meer, grünes Gras oben, salzige Luft.","https://upload.wikimedia.org/wikipedia/commons/4/4a/White_Cliffs_of_Dover_02.JPG","51.1295°N, 1.3656°E",3,["weiß","klippe","meer","steil","gras","salz"]),
    ("7821","Schloss Neuschwanstein","building","Märchenschloss in Bayern. Weiße Türme mit blauen Dächern, auf Bergspitze, umgeben von Wäldern, romantisch.","https://upload.wikimedia.org/wikipedia/commons/d/d7/Castle_Neuschwanstein.jpg","47.5576°N, 10.7498°E",2,["schloss","weiß","turm","berg","wald","märchenhaft"]),
    ("3068","Großes Blaues Loch","nature","Tiefe kreisförmige Unterwasser-Sinkhöhle vor Belize. Dunkelblauer Kreis im türkisen Meer, perfekt rund, tief.","https://upload.wikimedia.org/wikipedia/commons/8/88/Great_Blue_Hole.jpg","17.3158°N, 87.5347°W",4,["wasser","kreis","blau","tief","rund","dunkel"]),
    ("6473","Tower Bridge London","building","Klappbrücke über die Themse in London. Zwei steinerne Türme, blaue Stahlteile, viktorianischer Stil, Fluss darunter.","https://upload.wikimedia.org/wikipedia/commons/b/bd/Tower_Bridge_London_Twilight_-_November_2006.jpg","51.5055°N, 0.0754°W",3,["brücke","turm","fluss","blau","stein","urban"]),
    ("9237","Grand Canyon","nature","Riesige Schlucht in Arizona. Rot-orange Felsschichten, tiefe Schlucht, Colorado-Fluss darunter, weite Landschaft.","https://upload.wikimedia.org/wikipedia/commons/d/dd/Dawn_on_the_S_rim_of_the_Grand_Canyon_%288645178272%29.jpg","36.0544°N, 112.1401°W",2,["schlucht","rot","orange","tief","fels","weit"]),
    ("2581","Hagia Sophia","building","Byzantinische Kathedrale/Moschee in Istanbul. Große Kuppel, vier Minarette, rötlich-orange Außenwände, monumental.","https://upload.wikimedia.org/wikipedia/commons/2/2f/Aya_sofya.jpg","41.0086°N, 28.9802°E",3,["kuppel","orange","minarett","alt","monumental"]),
    ("4806","Mount Fuji","nature","Heiliger Vulkan in Japan. Schneebedeckter Kegel, symmetrisch, weiß-blau, oft mit Wolken umgeben, ikonisch.","https://upload.wikimedia.org/wikipedia/commons/5/52/Mt_Fuji_from_Lake_Yamanaka.jpg","35.3606°N, 138.7274°E",2,["berg","schnee","kegel","weiß","symmetrisch","heilig"]),
    ("7194","Iguazu Wasserfälle","nature","Massive Wasserfallketten an der Grenze Brasilien-Argentinien. Hunderte Kaskaden, weißer Schaum, grüner Dschungel, tosend.","https://upload.wikimedia.org/wikipedia/commons/5/5d/Iguazu_Falls_2009.jpg","25.6953°S, 54.4367°W",3,["wasser","wald","weiß","tosend","grün","feucht"]),
    ("5862","Cappadocia","nature","Felsentürme in Zentralanatolien. Bizarre weiße Steinformationen, Höhlenwohnungen, Heißluftballons am Himmel, surreal.","https://upload.wikimedia.org/wikipedia/commons/9/97/Cappadocia_Landscape_-_Cappadocia_-_Turkey_-_02.jpg","38.6431°N, 34.8289°E",4,["fels","weiß","höhle","bizarr","ballon","trocken"]),
    ("1438","Brandenburger Tor","monument","Klassizistisches Stadttor in Berlin. Säulen aus Sandstein, Quadriga oben, beige, urban, symbolisch.","https://upload.wikimedia.org/wikipedia/commons/b/be/Brandenburger_Tor_abends.jpg","52.5163°N, 13.3777°E",3,["tor","säulen","beige","urban","historisch"]),
    ("8351","Salar de Uyuni","nature","Größte Salzwüste der Welt in Bolivien. Endlose weiße Salzfläche, perfekt flach, bei Regen spiegelnd wie ein Spiegel.","https://upload.wikimedia.org/wikipedia/commons/3/3e/Sal_uyuni_2013.jpg","20.1338°S, 67.4891°W",3,["salz","weiß","flach","spiegel","weit","trocken"]),
    ("6724","Versailles Schloss","building","Königlicher Palast bei Paris. Goldverzierter Palast, lange Fassaden, Spiegelsaal, Gärten, prächtig, beige-gold.","https://upload.wikimedia.org/wikipedia/commons/8/8b/Vue_aerienne_du_domaine_de_Versailles_par_ToucanWings_-_Creative_Commons_By_Sa_3.0_-_073.jpg","48.8049°N, 2.1204°E",3,["schloss","gold","beige","garten","prächtig"]),
    ("3917","Galapagos Inseln","nature","Vulkanische Inseln im Pazifik. Schwarze Lavasteine, blaues Meer, einzigartige Tierwelt, sonnig, isoliert.","https://upload.wikimedia.org/wikipedia/commons/0/01/Galapagos-satellite-2002.jpg","0.7893°S, 90.9526°W",4,["insel","lava","schwarz","blau","tier","sonnig"]),
    ("5063","Plitvicer Seen","nature","Kaskadensystem in Kroatien. Türkises Wasser, Wasserfälle, grüner Wald, Holzstege, kristallklar, ruhig.","https://upload.wikimedia.org/wikipedia/commons/4/47/Plitvice_lakes_main.jpg","44.8654°N, 15.5820°E",4,["wasser","türkis","wald","wasserfall","klar","grün"]),
    ("7649","Petronas Towers","building","Zwillingstürme in Kuala Lumpur, Malaysia. Silberne Hochhaus-Zwillinge mit Skybridge, modern, glänzend, hoch.","https://upload.wikimedia.org/wikipedia/commons/0/06/Petronas_Panorama_II.jpg","3.1579°N, 101.7116°E",3,["turm","zwilling","silber","modern","hoch","glänzend"]),
    ("2486","Borobudur","monument","Buddhistische Tempelanlage in Indonesien. Stufenpyramide aus dunklem Stein, viele Stupas, Reliefs, terrassiert.","https://upload.wikimedia.org/wikipedia/commons/9/90/Borobudur-Nothwest-view.jpg","7.6079°S, 110.2038°E",4,["tempel","stein","pyramide","stupa","alt","grau"]),
    ("9582","Matterhorn","nature","Pyramidenförmiger Gipfel in den Alpen. Schwarz-weißer Berg, sehr spitz, schneebedeckt, ikonisch, Schweiz.","https://upload.wikimedia.org/wikipedia/commons/d/dc/3818_-_Riffelberg_-_Matterhorn_viewed_from_Gornergratbahn.JPG","45.9763°N, 7.6586°E",3,["berg","schnee","pyramide","spitz","weiß","schroff"]),
    ("4127","Loch Ness","nature","Tiefer länglicher See in Schottland. Dunkles Wasser, grüne Hügel, neblig, mystisch, kühl, Ruine am Ufer.","https://upload.wikimedia.org/wikipedia/commons/9/9d/Loch_Ness_from_Urquhart_Castle.JPG","57.3229°N, 4.4244°W",4,["wasser","see","dunkel","nebel","grün","mystisch"]),
    ("6815","Mont Saint-Michel","monument","Klosterinsel an der französischen Küste. Steinabtei auf Felseninsel, umgeben vom Meer bei Flut, gotisch, hoch.","https://upload.wikimedia.org/wikipedia/commons/0/07/Mont_Saint-Michel_-_2018-03-11.jpg","48.6361°N, 1.5115°W",3,["kloster","fels","meer","stein","gotisch","insel"]),
    ("1295","Halong Bay","nature","Vietnamesische Bucht mit Kalksteinfelsen. Smaragdgrünes Wasser, tausende Felseninseln, traditionelle Dschunken, neblig.","https://upload.wikimedia.org/wikipedia/commons/9/95/Ha_Long_Bay_in_the_Mist.jpg","20.9101°N, 107.1839°E",3,["wasser","fels","grün","insel","nebel","ruhig"]),
    ("8073","Chichen Itza","monument","Maya-Pyramide auf Yucatán. Stufenpyramide aus hellem Stein, El Castillo, quadratisch, beige, alt.","https://upload.wikimedia.org/wikipedia/commons/f/f6/Chichen_Itza_3.jpg","20.6843°N, 88.5678°W",3,["pyramide","stein","alt","beige","stufen","tempel"]),
    ("3540","Yellowstone","nature","Geysir-Nationalpark in Wyoming. Old Faithful, heiße Quellen, bunte Terrassen, Geysire, dampfend, vulkanisch.","https://upload.wikimedia.org/wikipedia/commons/4/40/Castle_Geyser_Eruption.jpg","44.4280°N, 110.5885°W",3,["geysir","dampf","heiß","bunt","wasser","vulkanisch"]),
    ("7902","Acropolis Athen","monument","Antike Tempelfestung über Athen. Marmorsäulen des Parthenon, hellbeige-weiß, auf Hügel, klassisch griechisch.","https://upload.wikimedia.org/wikipedia/commons/0/00/Athens_Acropolis.jpg","37.9715°N, 23.7257°E",3,["tempel","säulen","weiß","marmor","alt","hügel"]),
    ("5267","Bryce Canyon","nature","Amphitheater roter Felsnadeln in Utah. Hoodoos, orange-rot, vertikal, viele Spitzen, trocken, Schluchten.","https://upload.wikimedia.org/wikipedia/commons/3/3e/USA_09847_Bryce_Canyon_Luca_Galuzzi_2007.jpg","37.5930°N, 112.1871°W",4,["fels","rot","orange","nadel","trocken","spitz"]),
    ("4319","CN Tower","building","Telekommunikationsturm in Toronto. Schmaler grauer Turm mit Aussichtsplattform, sehr hoch, modern, urban.","https://upload.wikimedia.org/wikipedia/commons/3/3e/Toronto_-_ON_-_Toronto_Harbourfront7.jpg","43.6426°N, 79.3871°W",3,["turm","hoch","grau","modern","urban","schmal"]),
    ("9457","Cenotes Yucatán","nature","Unterirdische Süßwasser-Höhlensysteme in Mexiko. Türkises klares Wasser, Stalaktiten, dunkle Höhlen, kühl, mystisch.","https://upload.wikimedia.org/wikipedia/commons/1/19/Cenote_Samula_Dzitnup_Yucatan_Mexico.jpg","20.6843°N, 88.2000°W",4,["höhle","wasser","türkis","dunkel","unterirdisch","kühl"]),
]

assert len(TARGETS) == 50, f"Expected 50 targets, got {len(TARGETS)}"

rows = []
for code,name,cat,desc,img,coords,diff,feats in TARGETS:
    row = "(" + ",".join([
        sql_str(code), sql_str(name), sql_str(cat), sql_str(desc),
        sql_str(img), sql_str(coords), str(diff), sql_array(feats)
    ]) + ")"
    rows.append(row)

sql = (
    "INSERT INTO public.rv_targets "
    "(target_code, target_name, category, description, image_url, coordinates, difficulty, key_features) "
    "VALUES\n" + ",\n".join(rows) +
    "\nON CONFLICT (target_code) DO UPDATE SET "
    "target_name=EXCLUDED.target_name, category=EXCLUDED.category, "
    "description=EXCLUDED.description, image_url=EXCLUDED.image_url, "
    "coordinates=EXCLUDED.coordinates, difficulty=EXCLUDED.difficulty, "
    "key_features=EXCLUDED.key_features;"
)

os.makedirs("/tmp/ursprung_branches", exist_ok=True)
out = "/tmp/ursprung_branches/rv_targets.json"
with open(out, "w", encoding="utf-8") as f:
    json.dump({"query": sql}, f, ensure_ascii=False)
print(f"Wrote {out} ({os.path.getsize(out)} bytes) — {len(TARGETS)} targets")
