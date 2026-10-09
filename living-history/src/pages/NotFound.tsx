import { Link } from 'react-router-dom';

export default function NotFound() {
  return (
    <div className="container-page py-24 text-center">
      <p className="eyebrow">Lost to history</p>
      <h1 className="mt-3 text-4xl font-bold">We couldn’t find that page.</h1>
      <Link to="/" className="btn-primary mt-8">
        Back to Explore
      </Link>
    </div>
  );
}
