# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/application_model_examples'
require 'models/concerns/can_csv_import_examples'
require 'models/concerns/can_csv_import_text_module_examples'

RSpec.describe TextModule, type: :model do
  it_behaves_like 'ApplicationModel'
  it_behaves_like 'CanCsvImport'
  include_examples 'CanCsvImport - TextModule specific tests'
end
