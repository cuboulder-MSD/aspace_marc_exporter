require_relative 'lib/boulderSerializer'
require_relative 'lib/boulderMarc'
require_relative 'lib/boulderExporter'
require_relative 'lib/aspace_extensions'

MARCSerializer.add_decorator(BoulderMARCSerializer)
