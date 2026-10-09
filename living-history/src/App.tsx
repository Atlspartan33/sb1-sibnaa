import { Route, Routes } from 'react-router-dom';
import Layout from './components/Layout';
import Home from './pages/Home';
import CivilizationPage from './pages/CivilizationPage';
import EntryPage from './pages/EntryPage';
import MethodPage from './pages/MethodPage';
import StudioPage from './pages/StudioPage';
import NotFound from './pages/NotFound';

export default function App() {
  return (
    <Routes>
      <Route element={<Layout />}>
        <Route index element={<Home />} />
        <Route path="civilizations/:civilizationId" element={<CivilizationPage />} />
        <Route path="entries/:entryId" element={<EntryPage />} />
        <Route path="method" element={<MethodPage />} />
        <Route path="studio" element={<StudioPage />} />
        <Route path="*" element={<NotFound />} />
      </Route>
    </Routes>
  );
}
