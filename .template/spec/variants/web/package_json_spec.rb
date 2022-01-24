describe 'Web variant - package.json' do
  subject do
    JSON.parse(file('package.json').content)
  end

  describe 'Scripts' do
    it 'adds the script for running eslint' do
      expect(subject['scripts']).to include('eslint')
      expect(subject['scripts']).to include('eslint:fix')
    end

    it 'adds the script for running stylelint' do
      expect(subject['scripts']).to include('stylelint')
      expect(subject['scripts']).to include('stylelint:fix')
    end

    it 'adds the script for all lints' do
      expect(subject['scripts']).to include('lint')
      expect(subject['scripts']).to include('lint:fix')
    end

    it 'adds the script for bundling css' do
      expect(subject['scripts']).to include('build:css')
    end
  end

  describe 'Dependencies' do
    it 'adds I18n-js dependency' do
      expect(subject['dependencies']).to include('i18n-js')
    end

    it 'adds typescript dependencies' do
      expect(subject['dependencies']).to include('@babel/preset-typescript')
      expect(subject['dependencies']).to include('typescript')
    end

    it 'adds sass dependencies' do
      expect(subject['dependencies']).to include('sass')
    end
  end

  describe 'Development Dependencies' do
    it 'adds Nimble eslint config dependency' do
      expect(subject['devDependencies']).to include('@nimblehq/eslint-config-nimble')
    end

    it 'adds stylelint dependencies' do
      expect(subject['dependencies']).to include('stylelint')
      expect(subject['dependencies']).to include('stylelint-config-sass-guidelines')
      expect(subject['dependencies']).to include('stylelint-config-property-sort-order-smacss')
    end

    it 'adds postcss 8 dependencies' do
      expect(subject['dependencies']).to include('postcss')
      expect(subject['dependencies']['postcss']).to eq('8.4.5')
    end
  end
end
