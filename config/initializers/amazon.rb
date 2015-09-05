CarrierWave.configure do |config|
  config.fog_credentials = {
      :provider               => 'AWS',
      :aws_access_key_id      => 'AKIAJWDSZFBR4GSUIK5Q',
      :aws_secret_access_key  => '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',
      :region                 => 'ap-northeast-1'
  }
  config.fog_directory  = 'realchatting'
end