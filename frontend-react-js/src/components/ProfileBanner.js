import './ProfileBanner.css';

export default function ProfileBanner(props) {
  const backgroundImage = `url("https://assets.newcruddur.dev/banners/banner-${props.id}.jpg")`;
  console.log("banner",backgroundImage)
  const styles = {
    backgroundImage: backgroundImage,
    backgroundSize: 'cover',
    backgroundPosition: 'center',
  };

  return (
    <div 
      className="profile-banner"
      style={styles}
    ></div>
  );
}