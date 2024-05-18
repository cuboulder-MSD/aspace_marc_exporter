require_relative 'model/boulderSerializer'
require_relative 'model/boulderMarc'
require_relative 'model/boulderExporter'
require_relative 'lib/aspace_extensions'

MARCSerializer.add_decorator(BoulderMARCSerializer)
