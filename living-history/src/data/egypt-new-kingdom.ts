import type { EvidencedDetail, Entry } from '../types';

/*
 * Ten research-backed Scene Specs for New Kingdom Egypt (c. 1550–1070 BCE).
 * Every visual detail cites sources from ./sources.ts and carries a confidence level.
 * Low-confidence details are shown to readers but kept out of image prompts.
 */

const CIV = 'egypt-new-kingdom';
const CULTURE = 'Ancient Egyptian, New Kingdom';

// Baseline appearance shared by most Theban scenes.
const nileValleyPeople: EvidencedDetail = {
  detail:
    'Nile Valley Egyptians with a natural range of brown skin tones from light to deep brown, dark hair and eyes, varied faces, not a single uniform look',
  confidence: 'medium',
  sourceIds: ['schuenemann2017', 'robins1997'],
};

const sunWeathered: EvidencedDetail = {
  detail: 'sun-weathered skin and lean, work-hardened bodies typical of people who did manual labor outdoors',
  confidence: 'medium',
  sourceIds: ['tt69', 'lesko1994'],
};

const kohl: EvidencedDetail = {
  detail: 'dark kohl eyeliner worn by both men and women, applied in a simple line rather than dramatic wings',
  confidence: 'high',
  sourceIds: ['nebamun', 'robins1997'],
};

const HOLLYWOOD_FACES =
  'Hollywood casting defaults such as pale European features applied to everyone';

export const egyptNewKingdomEntries: Entry[] = [
  {
    id: 'deir-el-medina-tomb-builder',
    civilizationId: CIV,
    type: 'portrait',
    title: 'A Tomb-Builder of Deir el-Medina',
    dateLabel: 'c. 1250 BCE, reign of Ramesses II',
    summary:
      'The men who carved and painted the royal tombs in the Valley of the Kings were not slaves. They were skilled, salaried craftsmen who lived with their families in a walled village. Thousands of their notes, receipts, and letters survive, so we know more about their daily lives than about almost any other ancient community.',
    spec: {
      culture: CULTURE,
      region: 'Deir el-Medina, west bank of Thebes',
      period: { start: -1270, end: -1230 },
      subject:
        'environmental portrait of a middle-aged Egyptian stone-cutter pausing at the doorway of his mud-brick house, holding a copper chisel and a wooden mallet',
      setting:
        'a narrow street of the workmen’s village, whitewashed mud-brick houses, the bare limestone cliffs of the Theban hills behind',
      composition: 'waist-up portrait, eye level, subject slightly off-center, village street softly out of focus behind',
      lighting: 'early-morning sun raking low across the street, warm light and long shadows',
      appearance: [
        nileValleyPeople,
        sunWeathered,
        {
          detail: 'clean-shaven face and very short-cropped or shaved hair, as Egyptian men usually were',
          confidence: 'high',
          sourceIds: ['tt1', 'robins1997'],
        },
        {
          detail: 'fine limestone dust on his forearms and kilt from work in the tombs',
          confidence: 'low',
          sourceIds: [],
        },
      ],
      attire: [
        {
          detail: 'plain knee-length wrapped kilt of undyed, slightly worn linen, tied at the waist',
          confidence: 'high',
          sourceIds: ['vogelsang1993', 'tt1'],
        },
        {
          detail: 'bare chest; simple sandals of woven papyrus or palm fiber',
          confidence: 'high',
          sourceIds: ['vogelsang1993'],
        },
        {
          detail: 'a small protective amulet on a cord around the neck',
          confidence: 'medium',
          sourceIds: ['lesko1994'],
        },
      ],
      environment: [
        {
          detail: 'mud-brick houses with whitewashed walls and wooden doorframes, some painted red',
          confidence: 'high',
          sourceIds: ['bierbrier1982', 'lesko1994'],
        },
        {
          detail: 'pale limestone flakes (ostraca) with handwritten notes in black ink lying near the doorway',
          confidence: 'medium',
          sourceIds: ['lesko1994'],
        },
        {
          detail: 'copper chisel and wooden mallet, the actual tools used to cut tombs',
          confidence: 'high',
          sourceIds: ['bierbrier1982'],
        },
      ],
      avoid: [
        'slaves, chains, or overseers with whips',
        'pyramids',
        'Greek or Roman columns',
        'gold jewelry or royal regalia',
        'dramatic winged eyeliner',
        HOLLYWOOD_FACES,
      ],
      aspectRatio: '2:3',
    },
    mythsVsReality: [
      {
        myth: 'Royal tombs were built by slaves under the whip.',
        reality:
          'The Deir el-Medina workers were paid in grain, beer, oil, and fish. They worked in rotating shifts with regular days off, and their absence records give excuses like "brewing beer" or a family illness.',
        sourceIds: ['lesko1994', 'bierbrier1982'],
      },
    ],
    images: [],
  },

  {
    id: 'nebamun-banquet-guest',
    civilizationId: CIV,
    type: 'portrait',
    title: 'A Noblewoman at a Theban Banquet',
    dateLabel: 'c. 1350 BCE, reign of Amenhotep III',
    summary:
      'Elite Thebans held lavish banquets with music, wine, and flowers. The paintings from the tomb-chapel of Nebamun show guests in their finest pleated linen and broad collars, with lotus blossoms in hand.',
    spec: {
      culture: CULTURE,
      region: 'Thebes',
      period: { start: -1360, end: -1340 },
      subject:
        'portrait of an elite Egyptian woman seated at a banquet, holding a blue lotus flower to her nose, with other guests and musicians softly blurred behind her',
      setting:
        'a columned reception hall of a wealthy Theban house, painted plastered walls, jars of wine on stands, garlands of flowers',
      composition: 'three-quarter portrait from the chest up, shallow depth of field, guests in the background',
      lighting: 'warm interior light from high windows and oil lamps, soft and golden',
      appearance: [
        nileValleyPeople,
        kohl,
        {
          detail: 'a heavy, long wig of many fine braids or crimped locks falling past the shoulders',
          confidence: 'high',
          sourceIds: ['nebamun', 'vogelsang1993'],
        },
        {
          detail: 'a small pale cone resting on top of the wig',
          confidence: 'medium',
          sourceIds: ['stevens2019', 'nebamun'],
        },
      ],
      attire: [
        {
          detail: 'a long, fine white linen dress with delicate pleating, layered and draped over the shoulders',
          confidence: 'high',
          sourceIds: ['vogelsang1993', 'nebamun'],
        },
        {
          detail: 'a broad collar (wesekh) of many rows of blue, green, and red faience beads',
          confidence: 'high',
          sourceIds: ['nebamun', 'vogelsang1999'],
        },
        {
          detail: 'large gold or faience earrings and bracelets',
          confidence: 'high',
          sourceIds: ['nebamun'],
        },
      ],
      environment: [
        {
          detail: 'blue lotus flowers and floral garlands',
          confidence: 'high',
          sourceIds: ['nebamun'],
        },
        {
          detail: 'tall pottery wine jars wrapped with vines on stands, servants pouring wine',
          confidence: 'high',
          sourceIds: ['nebamun'],
        },
        {
          detail: 'female musicians with a double flute and harp in the blurred background',
          confidence: 'high',
          sourceIds: ['nebamun'],
        },
      ],
      avoid: [
        'brightly colored silk or satin gowns',
        'Cleopatra-style costume',
        'snake headdress or royal crown',
        'nudity',
        HOLLYWOOD_FACES,
      ],
      aspectRatio: '2:3',
    },
    mythsVsReality: [
      {
        myth: 'The cones on people’s heads in tomb paintings were only artistic symbols.',
        reality:
          'In 2019, archaeologists found real wax cones on two burials at Amarna. They existed as physical objects, though how often they were worn and what they were for is still debated.',
        sourceIds: ['stevens2019'],
      },
      {
        myth: 'Eyeliner was a feminine glamour statement.',
        reality: 'Men and women of many classes wore kohl. It may also have protected against glare, flies, and eye infections.',
        sourceIds: ['robins1997'],
      },
    ],
    images: [],
  },

  {
    id: 'linen-across-classes',
    civilizationId: CIV,
    type: 'attire',
    title: 'Linen Across the Classes',
    dateLabel: 'c. 1400–1200 BCE',
    summary:
      'Almost everyone in Egypt wore linen, but its quality signaled status. A farmer wore a coarse loincloth, and royalty wore linen so fine it was nearly transparent. Most clothing was white or undyed. Color came from jewelry, collars, and sashes rather than the cloth.',
    spec: {
      culture: CULTURE,
      region: 'Thebes',
      period: { start: -1400, end: -1200 },
      subject:
        'three Egyptians standing side by side in a fashion-plate style lineup: a farmer, a scribe, and a high official, showing how clothing quality changed with status',
      setting: 'plain mud-brick courtyard wall as a neutral backdrop, packed-earth floor',
      composition: 'full-length, straight-on, evenly spaced, like a museum costume study',
      lighting: 'soft, even open shade so fabric texture and pleating are clearly visible',
      appearance: [nileValleyPeople, kohl],
      attire: [
        {
          detail: 'farmer: simple coarse linen loincloth or short wrap kilt, barefoot',
          confidence: 'high',
          sourceIds: ['vogelsang1993', 'tt69'],
        },
        {
          detail: 'scribe: longer, cleaner white linen kilt reaching mid-calf, simple sandals, scribal palette tucked under the arm',
          confidence: 'high',
          sourceIds: ['vogelsang1993'],
        },
        {
          detail:
            'high official: finely pleated, semi-sheer linen kilt with a long pleated overgarment or bag-tunic, broad beaded collar, gold armlets, wig',
          confidence: 'high',
          sourceIds: ['vogelsang1993', 'vogelsang1999'],
        },
        {
          detail: 'all garments in white or natural undyed linen; color comes only from jewelry and collars',
          confidence: 'high',
          sourceIds: ['vogelsang1993', 'kemp2001'],
        },
      ],
      environment: [
        {
          detail: 'a few props showing how linen was made: a bundle of flax stalks and a drop spindle on a low stool',
          confidence: 'medium',
          sourceIds: ['kemp2001'],
        },
      ],
      avoid: ['dyed or patterned robes', 'silk', 'togas', 'capes', 'fantasy armor', HOLLYWOOD_FACES],
      aspectRatio: '3:2',
    },
    mythsVsReality: [
      {
        myth: 'Egyptians wore brightly colored robes and silks.',
        reality:
          'Linen is hard to dye, so nearly all Egyptian clothing was white or natural. Status showed in how fine and finely pleated the linen was.',
        sourceIds: ['vogelsang1993', 'kemp2001'],
      },
    ],
    images: [],
  },

  {
    id: 'karnak-hypostyle-in-color',
    civilizationId: CIV,
    type: 'place',
    title: 'The Great Hypostyle Hall of Karnak, in Full Color',
    dateLabel: 'c. 1280 BCE, reign of Ramesses II',
    summary:
      'Today it is a forest of sandstone columns open to the sky. In its time, the Great Hypostyle Hall had a roof, was dim and filled with incense, and was covered in brightly painted reliefs. It was a sacred space that most ordinary Egyptians never entered.',
    spec: {
      culture: CULTURE,
      region: 'Karnak temple complex, Thebes',
      period: { start: -1290, end: -1270 },
      subject:
        'the interior of the Great Hypostyle Hall at Karnak as newly completed: rows of massive columns with open papyrus-flower capitals, a small procession of shaven-headed priests in white linen crossing the central aisle',
      setting: 'inside the roofed hall, looking down the central aisle of the tallest columns',
      composition: 'wide-angle, low viewpoint looking up and down the aisle, people small to show the enormous scale',
      lighting:
        'dim interior lit by narrow shafts of sunlight through stone-grilled clerestory windows high above, haze of incense smoke catching the light',
      appearance: [
        nileValleyPeople,
        {
          detail: 'priests with fully shaved heads',
          confidence: 'high',
          sourceIds: ['wilkinson2000'],
        },
      ],
      attire: [
        {
          detail: 'priests in plain, bright white linen kilts and robes, barefoot or in white papyrus sandals',
          confidence: 'medium',
          sourceIds: ['wilkinson2000', 'vogelsang1993'],
        },
      ],
      environment: [
        {
          detail:
            'enormous columns, the central row about 21 meters tall with open papyrus capitals, outer rows shorter with closed-bud capitals',
          confidence: 'high',
          sourceIds: ['karnakProject', 'wilkinson2000'],
        },
        {
          detail:
            'every surface carved with reliefs of kings and gods and painted in vivid red, blue, yellow, green, and white',
          confidence: 'high',
          sourceIds: ['karnakProject'],
        },
        {
          detail: 'a stone roof overhead painted with stars and vultures on a blue ground',
          confidence: 'medium',
          sourceIds: ['wilkinson2000'],
        },
      ],
      avoid: [
        'ruins, broken columns, or open sky overhead',
        'bare unpainted sandstone',
        'tourists',
        'sand dunes inside the hall',
        HOLLYWOOD_FACES,
      ],
      aspectRatio: '16:9',
    },
    mythsVsReality: [
      {
        myth: 'Egyptian temples were sand-colored stone.',
        reality:
          'Temples were brightly painted. Traces of the original pigment still survive on many reliefs at Karnak, and conservation work keeps revealing more.',
        sourceIds: ['karnakProject'],
      },
      {
        myth: 'Temples were public gathering places.',
        reality:
          'The inner halls were restricted to priests and the king. Ordinary people mostly met the gods at the outer gates and during festivals.',
        sourceIds: ['wilkinson2000'],
      },
    ],
    images: [],
  },

  {
    id: 'theban-harbor-market',
    civilizationId: CIV,
    type: 'daily-life',
    title: 'Market Day at the Theban Riverbank',
    dateLabel: 'c. 1400 BCE, reign of Amenhotep III',
    summary:
      'Egypt had no coins. Goods were valued in deben, a unit of weight in copper, and paid for in kind, such as a pair of sandals for a measure of grain. Tomb paintings show market stalls at the riverbank where ships from the Levant unloaded wine, oil, and foreign goods.',
    spec: {
      culture: CULTURE,
      region: 'Harbor of Thebes on the Nile',
      period: { start: -1410, end: -1380 },
      subject:
        'a busy open-air market at the Nile riverbank: Egyptian men and women seated behind baskets and mats of goods, bartering with customers, while a Levantine trading ship unloads amphorae in the background',
      setting: 'mudbank of the Nile with wooden river boats moored, palm trees and fields across the water',
      composition: 'eye-level documentary street scene, crowded foreground, ship in the mid-ground',
      lighting: 'bright late-morning sun with shade from simple reed awnings',
      appearance: [
        nileValleyPeople,
        sunWeathered,
        {
          detail: 'Levantine merchants with full beards and longer hair bound with headbands',
          confidence: 'high',
          sourceIds: ['tt162'],
        },
      ],
      attire: [
        {
          detail: 'Egyptian traders in simple white or undyed linen kilts and sheath dresses',
          confidence: 'high',
          sourceIds: ['vogelsang1993', 'tt162'],
        },
        {
          detail: 'Levantine merchants in long, wrapped woolen garments with colored bands and fringes, standing out from the Egyptians in white',
          confidence: 'high',
          sourceIds: ['tt162'],
        },
      ],
      environment: [
        {
          detail: 'goods on mats and in baskets: bread, fish, vegetables, sandals, bolts of linen, pottery',
          confidence: 'high',
          sourceIds: ['tt162', 'janssen1975'],
        },
        {
          detail: 'Canaanite storage jars (amphorae) carried down a gangplank from a seagoing ship',
          confidence: 'high',
          sourceIds: ['tt162'],
        },
        {
          detail: 'a balance scale being used to weigh goods',
          confidence: 'medium',
          sourceIds: ['janssen1975'],
        },
      ],
      avoid: ['coins or paper money', 'camels', 'Arab-style souk architecture', 'turbans', HOLLYWOOD_FACES],
      aspectRatio: '16:9',
    },
    mythsVsReality: [
      {
        myth: 'Ancient markets ran on gold coins.',
        reality:
          'New Kingdom Egypt used no coinage. Prices were reckoned in deben of copper or measures of grain, but goods were swapped directly.',
        sourceIds: ['janssen1975'],
      },
    ],
    images: [],
  },

  {
    id: 'grain-harvest',
    civilizationId: CIV,
    type: 'daily-life',
    title: 'Harvest Time in the Theban Fields',
    dateLabel: 'c. 1400 BCE, reign of Thutmose IV',
    summary:
      'Most Egyptians were farmers. At harvest, men cut grain with sickles, women and children gleaned the leftovers, and scribes measured the fields and recorded the crop for taxation, as the tomb of Menna shows in detail.',
    spec: {
      culture: CULTURE,
      region: 'Fields of the Theban west bank',
      period: { start: -1410, end: -1390 },
      subject:
        'a farming family harvesting emmer wheat: men cutting stalks high with sickles, women gathering sheaves into baskets, children gleaning, and a scribe in the background measuring the field with a knotted rope',
      setting: 'flat golden fields beside an irrigation canal, date palms and a sycamore fig tree for shade, the Theban cliffs on the horizon',
      composition: 'wide documentary scene at eye level, workers in the foreground, scribe in the mid-ground',
      lighting: 'hot midday sun, bright and slightly hazy',
      appearance: [nileValleyPeople, sunWeathered],
      attire: [
        {
          detail: 'men in short linen loincloths or kilts, some with a simple cloth tied over the head against the sun',
          confidence: 'high',
          sourceIds: ['tt69', 'vogelsang1993'],
        },
        {
          detail: 'women in simple sheath dresses of undyed linen, hair tied back',
          confidence: 'high',
          sourceIds: ['tt69'],
        },
        {
          detail: 'scribe in a longer white kilt with a scribal palette',
          confidence: 'high',
          sourceIds: ['tt69'],
        },
      ],
      environment: [
        {
          detail: 'sickles with a wooden handle and inset flint teeth, cutting the stalk just below the ear',
          confidence: 'high',
          sourceIds: ['tt69', 'kemp2006'],
        },
        {
          detail: 'large rope nets or baskets carrying grain to a threshing floor where cattle tread the sheaves',
          confidence: 'high',
          sourceIds: ['tt69'],
        },
        {
          detail: 'a jar of water hanging in the shade of the tree',
          confidence: 'medium',
          sourceIds: ['tt69'],
        },
      ],
      avoid: ['metal scythes', 'horses pulling plows', 'tractors or modern tools', HOLLYWOOD_FACES],
      aspectRatio: '16:9',
    },
    mythsVsReality: [
      {
        myth: 'Ancient Egypt was mostly pharaohs, priests, and pyramids.',
        reality:
          'The vast majority of Egyptians were farmers. The state ran on carefully recorded harvests, which scribes measured field by field.',
        sourceIds: ['tt69', 'kemp2006'],
      },
    ],
    images: [],
  },

  {
    id: 'scribe-at-work',
    civilizationId: CIV,
    type: 'portrait',
    title: 'A Scribe at Work',
    dateLabel: 'c. 1250 BCE, Ramesside period',
    summary:
      'Probably only a small fraction of Egyptians could read and write, and those who could held real power. Scribes ran the state: they counted grain, wrote letters, and kept accounts. Students copied texts praising the scribal life over every other trade.',
    spec: {
      culture: CULTURE,
      region: 'Thebes',
      period: { start: -1280, end: -1200 },
      subject:
        'a young Egyptian scribe sitting cross-legged on a reed mat, his linen kilt pulled taut across his lap as a writing surface, writing hieratic script on a papyrus roll with a rush pen',
      setting: 'shaded portico of an administrative building, stacked papyrus rolls and pottery jars nearby',
      composition: 'medium shot slightly above eye level, focus on hands and papyrus, face in concentration',
      lighting: 'soft reflected daylight in deep shade, bright courtyard behind',
      appearance: [
        nileValleyPeople,
        {
          detail: 'clean-shaven, short hair or a short simple wig',
          confidence: 'high',
          sourceIds: ['robins1997'],
        },
      ],
      attire: [
        {
          detail: 'white linen kilt and a light linen shirt or tunic',
          confidence: 'high',
          sourceIds: ['vogelsang1993'],
        },
      ],
      environment: [
        {
          detail:
            'a narrow wooden scribal palette with two ink wells, one red and one black, and a slot holding thin rush pens',
          confidence: 'high',
          sourceIds: ['kemp2006'],
        },
        {
          detail: 'a small water pot for wetting the ink cakes',
          confidence: 'high',
          sourceIds: ['kemp2006'],
        },
        {
          detail: 'a papyrus roll with columns of cursive hieratic script in black ink, headings in red',
          confidence: 'high',
          sourceIds: ['kemp2006'],
        },
      ],
      avoid: [
        'carved stone hieroglyphs on the papyrus',
        'quill pens or feather pens',
        'books or paper',
        'desks or chairs',
        HOLLYWOOD_FACES,
      ],
      aspectRatio: '3:2',
    },
    mythsVsReality: [
      {
        myth: 'Egyptians wrote everything in pictorial hieroglyphs.',
        reality:
          'Hieroglyphs were for monuments. Day-to-day writing on papyrus and pottery used hieratic, a fast cursive script.',
        sourceIds: ['kemp2006'],
      },
      {
        myth: 'Most Egyptians could read.',
        reality: 'Estimates suggest only a small percentage of the population was literate.',
        sourceIds: ['baines1983'],
      },
    ],
    images: [],
  },

  {
    id: 'opet-festival',
    civilizationId: CIV,
    type: 'moment',
    title: 'The Opet Festival Procession',
    dateLabel: 'c. 1330 BCE, reign of Tutankhamun',
    summary:
      'Every year during the Nile flood, the god Amun traveled from Karnak to Luxor Temple in a gilded boat-shaped shrine. Priests carried it on their shoulders, crowds lined the route, and musicians, dancers, and acrobats performed. Feasting lasted for weeks.',
    spec: {
      culture: CULTURE,
      region: 'Processional route between Karnak and Luxor Temple, Thebes',
      period: { start: -1336, end: -1327 },
      subject:
        'the gilded barque shrine of Amun carried on long poles on the shoulders of shaven-headed priests, followed by musicians, women shaking sistrums, and drummers, through a cheering crowd',
      setting: 'a temple gateway hung with tall colored banners on cedar flagpoles, the Nile in flood visible beyond',
      composition: 'dramatic eye-level view from inside the crowd, barque coming toward the camera, crowd framing both sides',
      lighting: 'bright morning sun, dust and incense in the air',
      appearance: [
        nileValleyPeople,
        {
          detail: 'Nubian drummers and dancers among the performers, as shown in the procession reliefs',
          confidence: 'high',
          sourceIds: ['opet1994'],
        },
        {
          detail: 'priests with fully shaved heads',
          confidence: 'high',
          sourceIds: ['opet1994', 'wilkinson2000'],
        },
      ],
      attire: [
        {
          detail: 'priests in white linen kilts and long robes',
          confidence: 'high',
          sourceIds: ['opet1994'],
        },
        {
          detail: 'crowd in everyday white linen with flower garlands for the festival',
          confidence: 'medium',
          sourceIds: ['vogelsang1993'],
        },
      ],
      environment: [
        {
          detail: 'a boat-shaped gilded shrine with ram-head prow and stern (the ram is sacred to Amun), veiled cabin in the center',
          confidence: 'high',
          sourceIds: ['opet1994'],
        },
        {
          detail: 'musicians with sistrums, clappers, drums, and lutes',
          confidence: 'high',
          sourceIds: ['opet1994'],
        },
        {
          detail: 'offerings of bread, fowl, and jars of beer stacked along the route',
          confidence: 'medium',
          sourceIds: ['opet1994'],
        },
      ],
      avoid: [
        'the pharaoh riding a chariot through the crowd',
        'a gold sarcophagus',
        'slaves pulling stone blocks',
        'nudity',
        HOLLYWOOD_FACES,
      ],
      aspectRatio: '16:9',
    },
    mythsVsReality: [
      {
        myth: 'Egyptian religion was gloomy and obsessed with death.',
        reality:
          'Festivals like Opet were huge public celebrations with music, dancing, and free food and beer. Under Ramesses III the festival lasted 27 days.',
        sourceIds: ['opet1994', 'wilkinson2000'],
      },
    ],
    images: [],
  },

  {
    id: 'nubian-prince-tribute',
    civilizationId: CIV,
    type: 'portrait',
    title: 'A Nubian Prince at the Court of Tutankhamun',
    dateLabel: 'c. 1330 BCE',
    summary:
      'Nubia (Kush) was both ruled by Egypt and part of the elite world of the New Kingdom. Nubian princes were raised at the Egyptian court, Nubians served as officers and police (the Medjay), and the Nubian fan-bearer Maiherpri was buried in the Valley of the Kings. The tomb of Huy, Tutankhamun’s Viceroy of Kush, shows Nubian princes arriving in splendor.',
    spec: {
      culture: 'Nubian (Kushite) noble at the Egyptian court, New Kingdom',
      region: 'Thebes, with delegates from Kush (modern Sudan)',
      period: { start: -1336, end: -1327 },
      subject:
        'a Nubian prince in a formal procession presenting gold rings to the Egyptian viceroy, a princess in an ox-drawn chariot under a parasol behind him',
      setting: 'an open courtyard of state with painted columns, Egyptian officials looking on',
      composition: 'portrait-led scene: the prince sharp in the foreground, procession behind him',
      lighting: 'bright, clean daylight',
      appearance: [
        {
          detail: 'dark brown to deep brown skin, short tightly curled hair, as consistently shown in Egyptian art of Nubians',
          confidence: 'high',
          sourceIds: ['tt40', 'kv36'],
        },
        {
          detail: 'Egyptian officials in the background with a range of lighter brown skin tones',
          confidence: 'medium',
          sourceIds: ['schuenemann2017', 'robins1997'],
        },
      ],
      attire: [
        {
          detail: 'fine Egyptian-style pleated linen garments combined with Nubian elements: a leopard-skin sash and an ostrich feather in the hair',
          confidence: 'high',
          sourceIds: ['tt40'],
        },
        {
          detail: 'large gold hoop earrings, gold armlets and bracelets',
          confidence: 'high',
          sourceIds: ['tt40'],
        },
      ],
      environment: [
        {
          detail: 'tribute of gold rings, bags of gold dust, ebony logs, ivory tusks, and leopard skins',
          confidence: 'high',
          sourceIds: ['tt40'],
        },
        {
          detail: 'a Nubian princess riding in a chariot drawn by oxen under a parasol',
          confidence: 'high',
          sourceIds: ['tt40'],
        },
      ],
      avoid: [
        'chains, shackles, or depicting the prince as a captive',
        'generic "tribal" costume from other regions or eras',
        'face paint not shown in the sources',
        'grass skirts',
      ],
      aspectRatio: '2:3',
    },
    mythsVsReality: [
      {
        myth: 'Nubians appear in Egyptian history only as enemies or captives.',
        reality:
          'Nubians held high positions in New Kingdom Egypt, including royal fan-bearer, soldier, and police officer. Later, Kushite kings ruled all of Egypt as the 25th Dynasty.',
        sourceIds: ['kv36', 'tt40'],
      },
    ],
    images: [],
  },

  {
    id: 'first-recorded-strike',
    civilizationId: CIV,
    type: 'moment',
    title: 'The First Recorded Strike in History',
    dateLabel: 'c. 1157 BCE, Year 29 of Ramesses III',
    summary:
      'When their grain rations were weeks late, the tomb-builders of Deir el-Medina put down their tools, marched past the guard posts, and sat down outside the royal mortuary temples on the west bank. They declared that they were hungry and had no clothing, oil, fish, or vegetables. The scribe Amennakht recorded it all, and the workers were eventually paid.',
    spec: {
      culture: CULTURE,
      region: 'Royal mortuary temples, west bank of Thebes',
      period: { start: -1157, end: -1157 },
      subject:
        'a group of Egyptian tomb-builders sitting down in protest against the back wall of a great stone temple, arms folded, while worried officials in fine linen try to negotiate and a scribe records the scene',
      setting: 'the outer mud-brick enclosure wall of a royal mortuary temple, desert edge, cultivated fields in the distance',
      composition: 'eye-level documentary photograph with the seated workers in the foreground, officials standing and gesturing',
      lighting: 'late afternoon sun, long shadows, tired heat',
      appearance: [
        nileValleyPeople,
        sunWeathered,
        {
          detail: 'thin, frustrated faces of men who have gone short on rations',
          confidence: 'medium',
          sourceIds: ['turinStrike'],
        },
      ],
      attire: [
        {
          detail: 'workers in worn, patched linen kilts',
          confidence: 'medium',
          sourceIds: ['turinStrike', 'vogelsang1993'],
        },
        {
          detail: 'officials in fine pleated linen with wigs and staffs of office',
          confidence: 'high',
          sourceIds: ['vogelsang1993'],
        },
      ],
      environment: [
        {
          detail: 'empty grain sacks and baskets at the workers’ feet',
          confidence: 'low',
          sourceIds: [],
        },
        {
          detail: 'a scribe with a palette writing on papyrus',
          confidence: 'high',
          sourceIds: ['turinStrike'],
        },
      ],
      avoid: ['riots, weapons, or violence', 'soldiers attacking', 'modern protest signs', HOLLYWOOD_FACES],
      aspectRatio: '16:9',
    },
    mythsVsReality: [
      {
        myth: 'Ancient workers had no voice.',
        reality:
          'The Turin Strike Papyrus records repeated, organized sit-down protests. The workers stated their demands, and the authorities negotiated and released rations.',
        sourceIds: ['turinStrike', 'lesko1994'],
      },
    ],
    images: [],
  },
];
