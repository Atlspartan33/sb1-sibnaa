import type { Civilization } from '../types';

const NATION_SPECIFIC_NOTE =
  'Before any images are made, this needs sources specific to the nation, review by advisors from descendant communities, ' +
  'and a clear rule about which ceremonial and sacred items must never be depicted.';

const DESCENDANT_COMMUNITY_NOTE =
  'Millions of descendants live in this region today. Reconstructions will be reviewed with scholars and advisors from those communities before publishing.';

export const civilizations: Civilization[] = [
  {
    id: 'egypt-new-kingdom',
    name: 'Egypt: The New Kingdom',
    era: 'New Kingdom (Dynasties 18–20)',
    region: 'Nile Valley, centered on Thebes (modern Luxor)',
    dateLabel: 'c. 1550–1070 BCE',
    period: { start: -1550, end: -1070 },
    location: { lat: 25.7, lng: 32.64 },
    status: 'published',
    blurb:
      'The age of Hatshepsut, Akhenaten, Tutankhamun, and Ramesses II, and of the farmers, scribes, and tomb-builders whose lives were painted on tomb walls in remarkable detail.',
  },
  {
    id: 'indus-valley',
    name: 'Indus Valley Civilization',
    era: 'Mature Harappan period',
    region: 'Indus River basin, modern Pakistan and northwest India',
    dateLabel: 'c. 2600–1900 BCE',
    period: { start: -2600, end: -1900 },
    location: { lat: 27.33, lng: 68.14 },
    status: 'in-research',
    blurb:
      'Planned cities like Mohenjo-daro and Harappa, with grid streets, covered drains, standardized weights, and a script that has never been deciphered.',
  },
  {
    id: 'old-babylon',
    name: 'Babylon',
    era: 'Old Babylonian period',
    region: 'Mesopotamia, modern Iraq',
    dateLabel: 'c. 1894–1595 BCE',
    period: { start: -1894, end: -1595 },
    location: { lat: 32.54, lng: 44.42 },
    status: 'in-research',
    blurb:
      'The city of Hammurabi and his law code, of clay-tablet schools, merchants, and mathematicians who counted in base 60.',
  },
  {
    id: 'kush-meroe',
    name: 'Kingdom of Kush: Meroë',
    era: 'Meroitic period',
    region: 'Middle Nile, modern Sudan',
    dateLabel: 'c. 300 BCE–350 CE',
    period: { start: -300, end: 350 },
    location: { lat: 16.94, lng: 33.75 },
    status: 'in-research',
    blurb:
      'A powerful African kingdom with ruling queens (kandakes), its own script, iron-working, and more pyramids than Egypt.',
  },
  {
    id: 'han-changan',
    name: 'Han Dynasty China',
    era: 'Western Han',
    region: 'Chang’an (modern Xi’an)',
    dateLabel: '206 BCE–9 CE',
    period: { start: -206, end: 9 },
    location: { lat: 34.27, lng: 108.9 },
    status: 'in-research',
    blurb:
      'The eastern end of the Silk Road: a vast walled capital of markets, palaces, paper-making, and a civil service that ran an empire.',
  },
  {
    id: 'imperial-rome',
    name: 'Imperial Rome',
    era: 'Early Empire',
    region: 'City of Rome',
    dateLabel: '27 BCE–235 CE',
    period: { start: -27, end: 235 },
    location: { lat: 41.9, lng: 12.5 },
    status: 'in-research',
    blurb:
      'A city of perhaps a million people: apartment blocks, public baths, bakeries, and a population drawn from every corner of the Mediterranean.',
  },
  {
    id: 'aksum',
    name: 'Kingdom of Aksum',
    era: 'Aksumite period',
    region: 'Highlands of modern Ethiopia and Eritrea',
    dateLabel: 'c. 100–940 CE',
    period: { start: 100, end: 940 },
    location: { lat: 14.13, lng: 38.72 },
    status: 'in-research',
    blurb:
      'A Red Sea trading power that minted its own gold coins, raised towering carved stelae, and was one of the first states to adopt Christianity.',
  },
  {
    id: 'classic-maya',
    name: 'Classic Maya: Tikal',
    era: 'Classic period',
    region: 'Petén lowlands, modern Guatemala',
    dateLabel: 'c. 250–900 CE',
    period: { start: 250, end: 900 },
    location: { lat: 17.22, lng: -89.62 },
    status: 'in-research',
    blurb:
      'Painted temple-pyramids rising above the rainforest, royal courts, ballgames, and a full writing system recording kings, wars, and astronomy.',
    researchNote: DESCENDANT_COMMUNITY_NOTE,
  },
  {
    id: 'angkor',
    name: 'Khmer Empire: Angkor',
    era: 'Angkorian period',
    region: 'Modern Cambodia',
    dateLabel: '802–1431 CE',
    period: { start: 802, end: 1431 },
    location: { lat: 13.41, lng: 103.87 },
    status: 'in-research',
    blurb:
      'A sprawling city of reservoirs and canals around Angkor Wat, one of the largest religious monuments ever built.',
  },
  {
    id: 'chaco-canyon',
    name: 'Chaco Canyon',
    era: 'Chacoan era',
    region: 'San Juan Basin, modern New Mexico',
    dateLabel: 'c. 850–1150 CE',
    period: { start: 850, end: 1150 },
    location: { lat: 36.06, lng: -107.96 },
    status: 'in-research',
    blurb:
      'Ancestral Puebloan great houses like Pueblo Bonito, multi-story buildings aligned to the sun and moon and linked by long, straight roads.',
    researchNote: NATION_SPECIFIC_NOTE,
  },
  {
    id: 'viking-birka',
    name: 'Viking-Age Scandinavia',
    era: 'Viking Age',
    region: 'Birka, Lake Mälaren, modern Sweden',
    dateLabel: 'c. 793–1066 CE',
    period: { start: 793, end: 1066 },
    location: { lat: 59.33, lng: 17.54 },
    status: 'in-research',
    blurb:
      'Trading towns, farmsteads, and seafarers who reached from Baghdad to Newfoundland, wearing brighter colors than the movies suggest and no horned helmets.',
  },
  {
    id: 'cahokia',
    name: 'Cahokia',
    era: 'Mississippian period',
    region: 'American Bottom, near modern St. Louis',
    dateLabel: 'c. 1050–1350 CE',
    period: { start: 1050, end: 1350 },
    location: { lat: 38.66, lng: -90.06 },
    status: 'in-research',
    blurb:
      'At its height around 1100 CE, the largest city north of Mexico, with earthen pyramids, plazas, and tens of thousands of residents.',
    researchNote: NATION_SPECIFIC_NOTE,
  },
  {
    id: 'great-zimbabwe',
    name: 'Great Zimbabwe',
    era: 'Zimbabwe culture',
    region: 'Southeastern Zimbabwe',
    dateLabel: 'c. 1100–1450 CE',
    period: { start: 1100, end: 1450 },
    location: { lat: -20.27, lng: 30.93 },
    status: 'in-research',
    blurb:
      'A great stone city built without mortar, at the center of a gold and ivory trade that reached the Indian Ocean and China.',
  },
  {
    id: 'mali-empire',
    name: 'Mali Empire',
    era: 'Imperial Mali',
    region: 'Upper Niger, with Timbuktu as a center of learning',
    dateLabel: 'c. 1235–1600 CE',
    period: { start: 1235, end: 1600 },
    location: { lat: 16.77, lng: -3.0 },
    status: 'in-research',
    blurb:
      'The empire of Mansa Musa, mud-brick mosques, manuscript libraries, and the gold that made West Africa famous across three continents.',
  },
  {
    id: 'mexica-tenochtitlan',
    name: 'Tenochtitlan',
    era: 'Late Postclassic',
    region: 'Valley of Mexico',
    dateLabel: 'c. 1325–1521 CE',
    period: { start: 1325, end: 1521 },
    location: { lat: 19.43, lng: -99.13 },
    status: 'in-research',
    blurb:
      'The Mexica island capital of causeways, canals, floating gardens (chinampas), and the great market at Tlatelolco.',
    researchNote: DESCENDANT_COMMUNITY_NOTE,
  },
  {
    id: 'inca-cusco',
    name: 'Inca Empire',
    era: 'Late Horizon',
    region: 'Cusco, Andes of modern Peru',
    dateLabel: 'c. 1438–1533 CE',
    period: { start: 1438, end: 1533 },
    location: { lat: -13.53, lng: -71.97 },
    status: 'in-research',
    blurb:
      'The largest empire in the Americas, run without a written script, using knotted-cord records (khipu), 40,000 km of roads, and finely woven textiles that served as wealth.',
    researchNote: DESCENDANT_COMMUNITY_NOTE,
  },
  {
    id: 'haudenosaunee',
    name: 'Haudenosaunee Confederacy',
    era: 'Early colonial era',
    region: 'Present-day New York and Ontario',
    dateLabel: 'c. 1600–1750 CE',
    period: { start: 1600, end: 1750 },
    location: { lat: 43.0, lng: -76.1 },
    status: 'in-research',
    blurb:
      'The Six Nations: longhouse villages, the Three Sisters agriculture, and one of the oldest participatory democracies in the world.',
    researchNote: NATION_SPECIFIC_NOTE,
  },
];

export function getCivilization(id: string): Civilization | undefined {
  return civilizations.find((c) => c.id === id);
}

/** Whether a civilization existed in the given year. */
export function isActiveIn(civ: Civilization, year: number): boolean {
  return civ.period.start <= year && year <= civ.period.end;
}
