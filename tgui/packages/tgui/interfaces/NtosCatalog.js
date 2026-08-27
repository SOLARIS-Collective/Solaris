import { useBackend } from '../backend';
import { Box, Button, Input, Section, Stack, Table } from '../components';
import { NtosWindow } from '../layouts';

export const NtosCatalog = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    PC_device_theme,
    current_view,
    current_category,
    search_query,
    chemicals = [],
    mechas = [],
    designs = [],
    guides = [],
  } = data;

  return (
    <NtosWindow width={750} height={700} theme={PC_device_theme} resizable>
      <NtosWindow.Content>
        <Stack vertical fill>
          {/* Fixed header section */}
          <Section>
            <Stack>
              <Stack.Item grow>
                <Box fontSize="1.5em" bold mb={1}>
                  Explorers Guide to the Frontier
                </Box>
                <Box color="label" mb={1}>
                  Dont Panic! Consult Engineering before panic. Or after.
                  Preferably before. Note: If smoke appears, documentation is
                  working as intended. Lastly, Nanotrasen reminds you that
                  explosions are rarely tax-deductible.
                </Box>
              </Stack.Item>
            </Stack>
          </Section>

          {/* Fixed view buttons */}
          <Section>
            <Stack vertical>
              <Stack.Item>
                <Stack>
                  <Stack.Item>
                    <Button
                      icon="book-open"
                      color={current_view === 'howto' ? 'good' : ''}
                      content="How To"
                      onClick={() => act('change_view', { view: 'howto' })}
                    />
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      icon="flask"
                      color={current_view === 'chemistry' ? 'good' : ''}
                      content="Chemistry"
                      onClick={() => act('change_view', { view: 'chemistry' })}
                    />
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      icon="medkit"
                      color={current_view === 'medical' ? 'good' : ''}
                      content="Medical"
                      onClick={() => act('change_view', { view: 'medical' })}
                    />
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      icon="glass-martini"
                      color={current_view === 'drinks' ? 'good' : ''}
                      content="Drinks"
                      onClick={() => act('change_view', { view: 'drinks' })}
                    />
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      icon="leaf"
                      color={current_view === 'misc' ? 'good' : ''}
                      content="Misc"
                      onClick={() => act('change_view', { view: 'misc' })}
                    />
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      icon="wrench"
                      color={current_view === 'designs' ? 'good' : ''}
                      content="Designs"
                      onClick={() => act('change_view', { view: 'designs' })}
                    />
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      icon="robot"
                      color={current_view === 'mechs' ? 'good' : ''}
                      content="Exosuits"
                      onClick={() => act('change_view', { view: 'mechs' })}
                    />
                  </Stack.Item>
                </Stack>
              </Stack.Item>
              <Stack.Item>
                <Stack>
                  <Stack.Item grow>
                    <Input
                      fluid
                      placeholder="Search..."
                      value={search_query}
                      onInput={(e, value) => act('search', { query: value })}
                    />
                  </Stack.Item>
                  {search_query && (
                    <Stack.Item>
                      <Button
                        icon="times"
                        content="Clear"
                        onClick={() => act('clear_search')}
                      />
                    </Stack.Item>
                  )}
                </Stack>
              </Stack.Item>
            </Stack>
          </Section>

          {/* Scrollable content area */}
          <Section fill scrollable mb={2}>
            {(current_view === 'chemistry' ||
              current_view === 'medical' ||
              current_view === 'drinks' ||
              current_view === 'misc') && (
              <ChemistryCatalog
                chemicals={chemicals}
                view={current_view}
                current_category={current_category}
                act={act}
              />
            )}
            {current_view === 'mechs' && <MechaCatalog mechas={mechas} />}
            {current_view === 'designs' && (
              <DesignsCatalog
                designs={designs}
                current_category={current_category}
                act={act}
              />
            )}
            {current_view === 'howto' && (
              <HowToCatalog
                guides={guides}
                current_category={current_category}
                act={act}
              />
            )}
          </Section>
        </Stack>
      </NtosWindow.Content>
    </NtosWindow>
  );
};

const ChemistryCatalog = (props, context) => {
  const { chemicals = [], view, current_category, act } = props;

  // Determine section title based on view
  const getSectionTitle = () => {
    switch (view) {
      case 'medical':
        return 'Medical Chemistry';
      case 'drinks':
        return 'Drinks & Beverages';
      case 'misc':
        return 'Miscellaneous';
      case 'chemistry':
      default:
        return 'Chemistry';
    }
  };

  if (chemicals.length === 0) {
    return (
      <Section>
        <Box color="label" textAlign="center" my={2}>
          No chemicals found matching your search.
        </Box>
      </Section>
    );
  }

  return (
    <Stack vertical>
      {/* Medical category filter buttons */}
      {view === 'medical' && (
        <Stack.Item>
          <Box fontSize="1.2em" bold mb={1}>
            {getSectionTitle()} ({chemicals.length} chemicals)
          </Box>
          <Stack fill mb={1}>
            <Stack.Item grow>
              <Button
                fluid
                selected={current_category === 'all'}
                onClick={() => act('change_category', { category: 'all' })}
              >
                All
              </Button>
            </Stack.Item>
            <Stack.Item grow>
              <Button
                fluid
                color="grey"
                selected={current_category === 'misc'}
                onClick={() => act('change_category', { category: 'misc' })}
              >
                Misc
              </Button>
            </Stack.Item>
            <Stack.Item grow>
              <Button
                fluid
                color="red"
                selected={current_category === 'brute'}
                onClick={() => act('change_category', { category: 'brute' })}
              >
                Brute
              </Button>
            </Stack.Item>
            <Stack.Item grow>
              <Button
                fluid
                color="orange"
                selected={current_category === 'burn'}
                onClick={() => act('change_category', { category: 'burn' })}
              >
                Burn
              </Button>
            </Stack.Item>
            <Stack.Item grow>
              <Button
                fluid
                color="green"
                selected={current_category === 'toxin'}
                onClick={() => act('change_category', { category: 'toxin' })}
              >
                Toxin
              </Button>
            </Stack.Item>
            <Stack.Item grow>
              <Button
                fluid
                color="blue"
                selected={current_category === 'oxygen'}
                onClick={() => act('change_category', { category: 'oxygen' })}
              >
                Oxygen
              </Button>
            </Stack.Item>
            <Stack.Item grow>
              <Button
                fluid
                color="purple"
                selected={current_category === 'omni'}
                onClick={() => act('change_category', { category: 'omni' })}
              >
                Omni
              </Button>
            </Stack.Item>
          </Stack>
        </Stack.Item>
      )}

      {/* Chemical list */}
      <Stack.Item>
        {view !== 'medical' && (
          <Section
            title={`${getSectionTitle()} (${chemicals.length} chemicals)`}
          >
            <Stack vertical>
              {chemicals.map((chemical) => (
                <Stack.Item key={chemical.type}>
                  <ChemicalEntry chemical={chemical} />
                </Stack.Item>
              ))}
            </Stack>
          </Section>
        )}
        {view === 'medical' && (
          <Stack vertical>
            {chemicals.map((chemical) => (
              <Stack.Item key={chemical.type}>
                <ChemicalEntry chemical={chemical} />
              </Stack.Item>
            ))}
          </Stack>
        )}
      </Stack.Item>
    </Stack>
  );
};

const ChemicalEntry = (props, context) => {
  const { chemical } = props;

  // Determine color based on category
  const getCategoryColor = (category) => {
    switch (category) {
      case 'medical':
        return '#4a90e2'; // Blue
      case 'chemistry':
        return '#50c878'; // Green
      case 'drinks':
        return '#e67e22'; // Orange
      case 'misc':
        return '#1abc9c'; // Teal
      default:
        return '#95a5a6'; // Gray
    }
  };

  return (
    <>
      <Box
        backgroundColor={getCategoryColor(chemical.category)}
        height="3px"
        mb={1}
      />
      <Section title={chemical.name} level={2}>
        <Stack vertical>
          <Stack.Item>
            <Box italic mb={1}>
              {chemical.description}
            </Box>
          </Stack.Item>

          {chemical.biogenerator_cost && (
            <Stack.Item>
              <Box bold color="teal" mb={0.5}>
                Biogenerator Cost: {chemical.biogenerator_cost} Biomass
              </Box>
            </Stack.Item>
          )}

          {chemical.recipes && chemical.recipes.length > 0 && (
            <Stack.Item>
              <Box bold mb={0.5} color="good">
                Recipes:
              </Box>
              <Stack vertical>
                {chemical.recipes.map((recipe, index) => (
                  <Stack.Item key={index}>
                    <RecipeEntry recipe={recipe} />
                  </Stack.Item>
                ))}
              </Stack>
            </Stack.Item>
          )}

          {(!chemical.recipes || chemical.recipes.length === 0) && (
            <Stack.Item>
              <Box color="label" fontSize="0.9em">
                No known chemical recipes. May be found naturally or created
                through other means.
              </Box>
            </Stack.Item>
          )}
        </Stack>
      </Section>
    </>
  );
};

const RecipeEntry = (props, context) => {
  const { recipe } = props;

  return (
    <Box backgroundColor="rgba(0, 0, 0, 0.33)" p={1} mb={0.5}>
      <Table>
        <Table.Row>
          <Table.Cell bold color="label" width="180px">
            Required:
          </Table.Cell>
          <Table.Cell>
            {recipe.required && recipe.required.length > 0 ? (
              recipe.required.map((req, i) => (
                <Box key={i}>
                  {req.amount}u {req.name}
                </Box>
              ))
            ) : (
              <Box color="label">None</Box>
            )}
          </Table.Cell>
        </Table.Row>

        {recipe.catalysts && recipe.catalysts.length > 0 && (
          <Table.Row>
            <Table.Cell bold color="label" width="180px">
              Catalysts:
            </Table.Cell>
            <Table.Cell>
              {recipe.catalysts.map((cat, i) => (
                <Box key={i}>
                  {cat.amount}u {cat.name}
                </Box>
              ))}
            </Table.Cell>
          </Table.Row>
        )}

        <Table.Row>
          <Table.Cell bold color="label" width="180px">
            Produces:
          </Table.Cell>
          <Table.Cell>
            <Box color="good">{recipe.produces}u</Box>
          </Table.Cell>
        </Table.Row>

        {recipe.temperature && (
          <Table.Row>
            <Table.Cell bold color="label" width="180px">
              Temperature:
            </Table.Cell>
            <Table.Cell>
              <Box color={recipe.is_cold ? 'blue' : 'orange'}>
                {recipe.is_cold ? '< ' : '> '}
                {recipe.temperature}K
              </Box>
            </Table.Cell>
          </Table.Row>
        )}
      </Table>
    </Box>
  );
};

const MechaCatalog = (props, context) => {
  const { mechas = [] } = props;

  if (mechas.length === 0) {
    return (
      <Section>
        <Box color="label" textAlign="center" my={2}>
          No exosuits found matching your search.
        </Box>
      </Section>
    );
  }

  return (
    <Section title={`Exosuit Construction Guide (${mechas.length} exosuits)`}>
      <Stack vertical>
        {mechas.map((mecha, index) => (
          <Stack.Item key={index}>
            <MechaEntry mecha={mecha} />
          </Stack.Item>
        ))}
      </Stack>
    </Section>
  );
};

const MechaEntry = (props, context) => {
  const { mecha } = props;

  // Determine color based on category
  const getCategoryColor = (category) => {
    switch (category) {
      case 'working':
        return '#f39c12'; // Orange for working mechs
      case 'combat':
        return '#e74c3c'; // Red for combat mechs
      case 'medical':
        return '#3498db'; // Blue for medical mechs
      case 'advanced':
        return '#9b59b6'; // Purple for advanced mechs
      case 'clown':
        return '#ff69b4'; // Hot pink for H.O.N.K!
      default:
        return '#95a5a6'; // Gray
    }
  };

  return (
    <>
      <Box
        backgroundColor={getCategoryColor(mecha.category)}
        height="3px"
        mb={1}
      />
      <Section title={mecha.name} level={2}>
        <Stack vertical>
          {/* Materials Required */}
          {mecha.materials && mecha.materials.length > 0 && (
            <Stack.Item>
              <Box bold mb={0.5} color="good">
                Total Materials Required:
              </Box>
              <Box backgroundColor="rgba(0, 0, 0, 0.33)" p={1} mb={1}>
                <Stack>
                  {mecha.materials.map((mat, i) => (
                    <Stack.Item key={i} mr={2}>
                      <Box>
                        <Box as="span" bold>
                          {mat.amount}
                        </Box>{' '}
                        {mat.name}
                      </Box>
                    </Stack.Item>
                  ))}
                </Stack>
              </Box>
            </Stack.Item>
          )}

          {/* Parts to Fabricate */}
          {mecha.parts && mecha.parts.length > 0 && (
            <Stack.Item>
              <Box bold mb={0.5} color="good">
                Step 1: Fabricate Parts (Exosuit Fabricator)
              </Box>
              <Box backgroundColor="rgba(0, 0, 0, 0.33)" p={1} mb={1}>
                <Stack vertical>
                  {mecha.parts.map((part, i) => (
                    <Stack.Item key={i}>
                      <Box>
                        <Box as="span" color="label">
                          •
                        </Box>{' '}
                        {part.name}
                      </Box>
                    </Stack.Item>
                  ))}
                </Stack>
              </Box>
            </Stack.Item>
          )}

          {/* Assembly Steps */}
          {mecha.assembly_steps && mecha.assembly_steps.length > 0 && (
            <Stack.Item>
              <Box bold mb={0.5} color="good">
                Step 2: Assembly Instructions
              </Box>
              <Stack vertical>
                {mecha.assembly_steps.map((step, i) => (
                  <Stack.Item key={i}>
                    <AssemblyStep step={step} />
                  </Stack.Item>
                ))}
              </Stack>
            </Stack.Item>
          )}
        </Stack>
      </Section>
    </>
  );
};

const AssemblyStep = (props, context) => {
  const { step } = props;

  return (
    <Box backgroundColor="rgba(0, 0, 0, 0.33)" p={1} mb={0.5}>
      <Stack>
        <Stack.Item>
          <Box
            backgroundColor="rgba(255, 255, 255, 0.1)"
            p={0.5}
            mr={1}
            width="30px"
            textAlign="center"
            bold
          >
            {step.number}
          </Box>
        </Stack.Item>
        <Stack.Item grow>
          <Box>
            {step.tool && (
              <Box color="orange" bold mb={0.5}>
                Tool: {step.tool}
              </Box>
            )}
            {step.item && (
              <Box color="blue" bold mb={0.5}>
                {step.amount && <Box as="span">{step.amount}x </Box>}
                {step.item}
              </Box>
            )}
            {step.action && <Box color="label">{step.action}</Box>}
          </Box>
        </Stack.Item>
      </Stack>
    </Box>
  );
};

const DesignsCatalog = (props, context) => {
  const { designs = [], current_category, act } = props;

  if (designs.length === 0) {
    return (
      <Box color="label" textAlign="center" my={2}>
        No designs found matching your search.
      </Box>
    );
  }

  return (
    <Stack vertical>
      {/* Title */}
      <Stack.Item>
        <Box fontSize="1.2em" bold mb={1}>
          Fabricator Designs ({designs.length} designs)
        </Box>
      </Stack.Item>

      {/* Category buttons */}
      <Stack.Item>
        <Stack fill>
          <Stack.Item grow>
            <Button
              fluid
              selected={current_category === 'all'}
              onClick={() => act('change_category', { category: 'all' })}
            >
              All
            </Button>
          </Stack.Item>
          <Stack.Item grow>
            <Button
              fluid
              color="blue"
              selected={current_category === 'autolathe'}
              onClick={() => act('change_category', { category: 'autolathe' })}
            >
              Autolathe
            </Button>
          </Stack.Item>
          <Stack.Item grow>
            <Button
              fluid
              color="purple"
              selected={current_category === 'protolathe'}
              onClick={() => act('change_category', { category: 'protolathe' })}
            >
              Protolathe
            </Button>
          </Stack.Item>
          <Stack.Item grow>
            <Button
              fluid
              color="green"
              selected={current_category === 'imprinter'}
              onClick={() => act('change_category', { category: 'imprinter' })}
            >
              Circuit Imprinter
            </Button>
          </Stack.Item>
          <Stack.Item grow>
            <Button
              fluid
              color="orange"
              selected={current_category === 'mechfab'}
              onClick={() => act('change_category', { category: 'mechfab' })}
            >
              Mech Fab
            </Button>
          </Stack.Item>
        </Stack>
      </Stack.Item>

      {/* Design entries */}
      {designs.map((design, index) => (
        <Stack.Item key={design.id || index}>
          <DesignEntry design={design} />
        </Stack.Item>
      ))}
    </Stack>
  );
};

const DesignEntry = (props, context) => {
  const { design } = props;

  return (
    <>
      <Box backgroundColor="#7f8c8d" height="3px" mb={1} />
      <Section title={design.name} level={2}>
        <Stack vertical>
          {design.description && (
            <Stack.Item>
              <Box italic mb={1} color="label">
                {design.description}
              </Box>
            </Stack.Item>
          )}

          {/* Fabricators */}
          {design.categories && design.categories.length > 0 && (
            <Stack.Item>
              <Box bold mb={0.5} color="good">
                Available at:
              </Box>
              <Box backgroundColor="rgba(0, 0, 0, 0.33)" p={1} mb={1}>
                <Stack>
                  {design.categories.map((fab, i) => (
                    <Stack.Item key={i}>
                      <Box color="cyan">
                        •{' '}
                        {fab && typeof fab === 'string'
                          ? fab.charAt(0).toUpperCase() +
                            fab.slice(1).replace('mechfab', 'Mech Fab')
                          : String(fab)}
                      </Box>
                    </Stack.Item>
                  ))}
                </Stack>
              </Box>
            </Stack.Item>
          )}

          {/* Departments */}
          {design.departments && design.departments.length > 0 && (
            <Stack.Item>
              <Box bold mb={0.5} color="good">
                Department Access:
              </Box>
              <Box backgroundColor="rgba(0, 0, 0, 0.33)" p={1} mb={1}>
                <Stack>
                  {design.departments.map((dept, i) => (
                    <Stack.Item key={i}>
                      <Box
                        color={
                          dept === 'All Departments' ? 'average' : 'yellow'
                        }
                      >
                        • {dept}
                      </Box>
                    </Stack.Item>
                  ))}
                </Stack>
              </Box>
            </Stack.Item>
          )}

          {/* Materials */}
          {design.materials && design.materials.length > 0 && (
            <Stack.Item>
              <Box bold mb={0.5} color="good">
                Materials Required:
              </Box>
              <Box backgroundColor="rgba(0, 0, 0, 0.33)" p={1} mb={1}>
                <Table>
                  {design.materials.map((mat, i) => (
                    <Table.Row key={i}>
                      <Table.Cell>
                        <Box color="label">{mat.name}</Box>
                      </Table.Cell>
                      <Table.Cell textAlign="right">
                        <Box bold color="good">
                          {mat.amount}
                        </Box>
                      </Table.Cell>
                    </Table.Row>
                  ))}
                </Table>
              </Box>
            </Stack.Item>
          )}

          {/* Research Requirements */}
          {design.research_nodes && design.research_nodes.length > 0 && (
            <Stack.Item>
              <Box bold mb={0.5} color="good">
                Requires Research:
              </Box>
              <Box backgroundColor="rgba(0, 0, 0, 0.33)" p={1} mb={1}>
                <Stack vertical>
                  {design.research_nodes.map((node, i) => (
                    <Stack.Item key={i}>
                      <Box color="purple">
                        • {node.name || node.id || 'Unknown Research Node'}
                      </Box>
                    </Stack.Item>
                  ))}
                </Stack>
              </Box>
            </Stack.Item>
          )}

          {/* Categories */}
          {design.categories && design.categories.length > 0 && (
            <Stack.Item>
              <Box fontSize="0.9em" color="label">
                Categories: {design.categories.join(', ')}
              </Box>
            </Stack.Item>
          )}
        </Stack>
      </Section>
    </>
  );
};

const HowToCatalog = (props, context) => {
  const { guides = [], current_category, act } = props;

  if (guides.length === 0) {
    return (
      <Box color="label" textAlign="center" my={2}>
        No guides found matching your search.
      </Box>
    );
  }

  // Get unique categories from guides for filter buttons
  const categorySet = new Set();
  guides.forEach((guide) => {
    if (guide.category && typeof guide.category === 'string') {
      categorySet.add(guide.category);
    }
  });
  const categories = Array.from(categorySet).sort();

  return (
    <Stack vertical>
      {/* Title and category filters */}
      <Stack.Item>
        <Box fontSize="1.2em" bold mb={1}>
          How-To Guides ({guides.length} guides)
        </Box>
        <Stack fill mb={1}>
          <Stack.Item grow>
            <Button
              fluid
              selected={current_category === 'all'}
              onClick={() => act('change_category', { category: 'all' })}
            >
              All
            </Button>
          </Stack.Item>
          {categories.map((category) => (
            <Stack.Item grow key={category}>
              <Button
                fluid
                color={getCategoryButtonColor(category)}
                selected={current_category === category}
                onClick={() => act('change_category', { category: category })}
              >
                {capitalizeFirst(category)}
              </Button>
            </Stack.Item>
          ))}
        </Stack>
      </Stack.Item>

      {/* Guide list */}
      <Stack.Item>
        <Stack vertical>
          {guides.map((guide, index) => (
            <Stack.Item key={index}>
              <GuideEntry guide={guide} />
            </Stack.Item>
          ))}
        </Stack>
      </Stack.Item>
    </Stack>
  );
};

const GuideEntry = (props, context) => {
  const { guide } = props;

  // Determine color based on category
  const getCategoryColor = (category) => {
    switch (category) {
      case 'medical':
        return '#4a90e2'; // Blue
      case 'navigation':
        return '#9b59b6'; // Purple
      case 'engineering':
        return '#e67e22'; // Orange
      case 'security':
        return '#e74c3c'; // Red
      case 'science':
        return '#1abc9c'; // Teal
      default:
        return '#95a5a6'; // Gray
    }
  };

  return (
    <>
      <Box
        backgroundColor={getCategoryColor(guide.category)}
        height="3px"
        mb={1}
      />
      <Section title={guide.title} level={2}>
        <Stack vertical>
          {guide.sections.map((section, index) => (
            <Stack.Item key={index}>
              <GuideSection section={section} />
            </Stack.Item>
          ))}
        </Stack>
      </Section>
    </>
  );
};

const GuideSection = (props, context) => {
  const { section } = props;

  return (
    <Box mb={2}>
      {section.heading && (
        <Box bold mb={0.5} color="good">
          {section.heading}
        </Box>
      )}

      {/* Text content */}
      {section.type === 'text' && (
        <Box backgroundColor="rgba(0, 0, 0, 0.33)" p={1}>
          {section.content}
        </Box>
      )}

      {/* Unordered list */}
      {section.type === 'list' && (
        <Box backgroundColor="rgba(0, 0, 0, 0.33)" p={1}>
          <Stack vertical>
            {section.items.map((item, i) => (
              <Stack.Item key={i}>
                <Box>• {item}</Box>
              </Stack.Item>
            ))}
          </Stack>
        </Box>
      )}

      {/* Ordered list */}
      {section.type === 'ordered' && (
        <Box backgroundColor="rgba(0, 0, 0, 0.33)" p={1}>
          <Stack vertical>
            {section.items.map((item, i) => (
              <Stack.Item key={i}>
                <Box>
                  {i + 1}. {item}
                </Box>
              </Stack.Item>
            ))}
          </Stack>
        </Box>
      )}
    </Box>
  );
};

// Helper function to capitalize first letter
const capitalizeFirst = (str) => {
  if (!str || typeof str !== 'string') return String(str || '');
  return str.charAt(0).toUpperCase() + str.slice(1);
};

// Helper function to get category button color
const getCategoryButtonColor = (category) => {
  switch (category) {
    case 'medical':
      return 'blue';
    case 'navigation':
      return 'purple';
    case 'engineering':
      return 'orange';
    case 'security':
      return 'red';
    case 'science':
      return 'teal';
    default:
      return 'grey';
  }
};
