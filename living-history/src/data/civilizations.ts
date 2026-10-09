import type { Civilization } from '../types';

const NATION_SPECIFIC_NOTE =
  'Before any images are made, this needs sources specific to the nation, review by advisors from descendant communities, ' +
  'and a clear rule about which ceremonial and sacred items must never be depicted.';

export const civilizations: Civilization[] = [
  {
    id: 'egypt-new-kingdom',
    name: 'Egypt: The New Kingdom',
    era: 'New Kingdom (Dynasties 18–20)',
    region: 'Nile Valley, centered on Thebes (modern Luxor)',
    dateLabel: 'c. 1550–1070 BCE',
    status: 'published',
    blurb:
      'The age of Hatshepsut, Akhenaten, Tutankhamun, and Ramesses II, and of the farmers, scribes, and tomb-builders whose lives were painted on tomb walls in remarkable detail.',
  },
  {
    id: 'cahokia',
    name: 'Cahokia',
    era: 'Mississippian period',
    region: 'American Bottom, near modern St. Louis',
    dateLabel: 'c. 1050–1350 CE',
    status: 'in-research',
    blurb:
      'At its height around 1100 CE, the largest city north of Mexico, with earthen pyramids, plazas, and tens of thousands of residents.',
    researchNote: NATION_SPECIFIC_NOTE,
  },
  {
    id: 'haudenosaunee',
    name: 'Haudenosaunee Confederacy',
    era: 'Early colonial era',
    region: 'Present-day New York and Ontario',
    dateLabel: 'c. 1600–1750 CE',
    status: 'in-research',
    blurb:
      'The Six Nations: longhouse villages, the Three Sisters agriculture, and one of the oldest participatory democracies in the world.',
    researchNote: NATION_SPECIFIC_NOTE,
  },
  {
    id: 'kush-meroe',
    name: 'Kingdom of Kush: Meroë',
    era: 'Meroitic period',
    region: 'Middle Nile, modern Sudan',
    dateLabel: 'c. 300 BCE–350 CE',
    status: 'in-research',
    blurb:
      'A powerful African kingdom with ruling queens (kandakes), its own script, iron-working, and more pyramids than Egypt.',
  },
  {
    id: 'mexica-tenochtitlan',
    name: 'Tenochtitlan',
    era: 'Late Postclassic',
    region: 'Valley of Mexico',
    dateLabel: 'c. 1325–1521 CE',
    status: 'in-research',
    blurb:
      'The Mexica island capital of causeways, canals, floating gardens (chinampas), and the great market at Tlatelolco.',
  },
];

export function getCivilization(id: string): Civilization | undefined {
  return civilizations.find((c) => c.id === id);
}
