class Profile
  include ActiveModel::Model
  attr_accessor :id, :username, :email, :password_digest, :bio, :image, :following, :type

  def to_hash
    {
      'username' => username,
      'email' => email,
      'password_digest' => password_digest,
      'bio' => bio,
      'image' => image,
      'following' => following
    }
  end
end
