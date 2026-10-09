import type { Source } from '../types';

/**
 * Shared source registry. Entries cite sources by id, so one source can back many details.
 * Tomb numbers (TT = Theban Tomb, KV = Valley of the Kings) are the standard Egyptological references.
 */
const sourceList: Source[] = [
  // Population and appearance
  {
    id: 'schuenemann2017',
    title: 'Ancient Egyptian mummy genomes suggest an increase of Sub-Saharan African ancestry in post-Roman periods',
    kind: 'study',
    author: 'Schuenemann, V. J. et al.',
    year: '2017',
    note: 'Nature Communications 8. Genomes from Abusir el-Meleq (Middle Egypt), c. 1400 BCE–400 CE. One site only, so it cannot speak for all of Egypt.',
  },
  {
    id: 'robins1997',
    title: 'The Art of Ancient Egypt',
    kind: 'book',
    author: 'Robins, G.',
    year: '1997',
    note: 'Explains artistic conventions such as reddish-brown skin for men and lighter, yellowish skin for women, which signal gender roles rather than literal skin tone.',
  },

  // Clothing and adornment
  {
    id: 'vogelsang1993',
    title: 'Pharaonic Egyptian Clothing',
    kind: 'book',
    author: 'Vogelsang-Eastwood, G.',
    year: '1993',
  },
  {
    id: 'vogelsang1999',
    title: "Tutankhamun's Wardrobe",
    kind: 'book',
    author: 'Vogelsang-Eastwood, G.',
    year: '1999',
  },
  {
    id: 'kemp2001',
    title: 'The Ancient Textile Industry at Amarna',
    kind: 'book',
    author: 'Kemp, B. & Vogelsang-Eastwood, G.',
    year: '2001',
  },
  {
    id: 'stevens2019',
    title: 'Archaeological evidence for the head cones of ancient Egypt',
    kind: 'study',
    author: 'Stevens, A. et al.',
    year: '2019',
    note: 'Antiquity 93. Physical wax cones found on two burials at Amarna.',
  },

  // Tombs and sites
  {
    id: 'tt1',
    title: 'Tomb of Sennedjem (TT1), Deir el-Medina',
    kind: 'site',
    note: 'Painted burial chamber of a Ramesside tomb-builder and his wife Iyneferti.',
  },
  {
    id: 'nebamun',
    title: 'Tomb-chapel paintings of Nebamun, Thebes',
    kind: 'artifact',
    year: 'c. 1350 BCE',
    note: 'Banquet, garden, and marsh-hunting scenes, now in the British Museum.',
  },
  {
    id: 'tt69',
    title: 'Tomb of Menna (TT69), Sheikh Abd el-Qurna',
    kind: 'site',
    note: 'Detailed agricultural scenes: measuring fields, harvesting, gleaning, and recording grain.',
  },
  {
    id: 'paheri',
    title: 'Tomb of Paheri (EK3), Elkab',
    kind: 'site',
    note: 'Agricultural cycle including flax being pulled up by the roots.',
  },
  {
    id: 'tt162',
    title: 'Tomb of Kenamun (TT162), Thebes',
    kind: 'site',
    note: 'Levantine merchant ships unloading at an Egyptian harbor next to market stalls. See Davies & Faulkner, "A Syrian Trading Venture to Egypt", JEA 33 (1947).',
  },
  {
    id: 'tt40',
    title: 'Tomb of Amenhotep called Huy (TT40), Qurnet Murai',
    kind: 'site',
    note: 'Huy was Viceroy of Kush under Tutankhamun. His tomb shows Nubian princes, a princess in an ox-drawn chariot, and tribute of gold.',
  },
  {
    id: 'kv36',
    title: 'Tomb of Maiherpri (KV36), Valley of the Kings',
    kind: 'site',
    note: 'Burial of a royal fan-bearer of Nubian origin; his Book of the Dead papyrus shows him with dark skin.',
  },
  {
    id: 'karnakProject',
    title: 'Karnak Great Hypostyle Hall Project',
    kind: 'project',
    author: 'Brand, P. et al., University of Memphis',
  },
  {
    id: 'wilkinson2000',
    title: 'The Complete Temples of Ancient Egypt',
    kind: 'book',
    author: 'Wilkinson, R. H.',
    year: '2000',
  },
  {
    id: 'opet1994',
    title: 'Reliefs and Inscriptions at Luxor Temple, Vol. 1: The Festival Procession of Opet in the Colonnade Hall',
    kind: 'book',
    author: 'The Epigraphic Survey, Oriental Institute',
    year: '1994',
  },

  // Workers, economy, literacy
  {
    id: 'lesko1994',
    title: 'Pharaoh’s Workers: The Villagers of Deir el Medina',
    kind: 'book',
    author: 'Lesko, L. H. (ed.)',
    year: '1994',
  },
  {
    id: 'bierbrier1982',
    title: 'The Tomb-Builders of the Pharaohs',
    kind: 'book',
    author: 'Bierbrier, M.',
    year: '1982',
  },
  {
    id: 'turinStrike',
    title: 'Turin Strike Papyrus',
    kind: 'text',
    year: 'Year 29 of Ramesses III (c. 1157 BCE)',
    note: 'Museo Egizio, Turin. The scribe Amennakht’s record of the tomb-builders’ protests over late rations.',
  },
  {
    id: 'janssen1975',
    title: 'Commodity Prices from the Ramessid Period',
    kind: 'book',
    author: 'Janssen, J. J.',
    year: '1975',
  },
  {
    id: 'baines1983',
    title: 'Four notes on literacy',
    kind: 'study',
    author: 'Baines, J. & Eyre, C.',
    year: '1983',
    note: 'Göttinger Miscellen 61. Estimates that only a small fraction of the population could read and write.',
  },
  {
    id: 'kemp2006',
    title: 'Ancient Egypt: Anatomy of a Civilization (2nd ed.)',
    kind: 'book',
    author: 'Kemp, B.',
    year: '2006',
  },
];

export const sources: Record<string, Source> = Object.fromEntries(sourceList.map((s) => [s.id, s]));
