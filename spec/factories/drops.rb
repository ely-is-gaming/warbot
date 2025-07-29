FactoryBot.define do
  factory :drop do
    status { 'approved' }
    owner { 'UserA' }
    reviewed_by { 'ModUser' }
    submitter { 'UserZ' }
    img_url { 'https://media.discordapp.net/ephemeral-attachments/...' }
    item { FactoryBot.build(:item) }
    team { FactoryBot.build(:team) }
  end
end
