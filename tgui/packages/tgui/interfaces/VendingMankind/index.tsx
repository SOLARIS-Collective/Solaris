import { createSearch } from 'common/string';
import { useBackend, useLocalState } from '../../backend';
import { Flex, Input, NoticeBox, Section, Table, Tabs } from '../../components';
import { Window } from '../../layouts';
import { Data } from './types';

import { CashSection, UserSection, VendingRow } from './VendingSections';

export const VendingMankind = (props, context) => {
  const { act, data } = useBackend<Data>(context);
  const {
    user,
    all_items_free,
    miningvendor,
    categories = [],
    product_records = [],
    coin_records = [],
    hidden_records = [],
    stock,
    current_amount,
    access,
  } = data;
  const [searchText, setSearchText] = useLocalState(context, 'searchText', '');
  const [selectedCategory, setSelectedCategory] = useLocalState(
    context,
    'category',
    categories[0] || 'Misc'
  );
  let inventory: any[] = [];
  let custom = false;
  if (data.vending_machine_input) {
    inventory = data.vending_machine_input;
    custom = true;
  } else {
    inventory = [...product_records, ...coin_records];
    if (data.extended_inventory) {
      inventory = [...inventory, ...hidden_records];
    }
  }
  // Just in case we still have undefined values in the list
  inventory = inventory.filter((item) => !!item);

  const testSearch = createSearch(searchText, (item: any) => item.name);
  const visibleInventory =
    (searchText.length > 0 && inventory.filter(testSearch)) ||
    (custom && inventory) ||
    inventory.filter((item) => item.category === selectedCategory);

  return (
    <Window title="Vending Machine" width={550} height={600} resizable>
      <Window.Content scrollable>
        {!all_items_free && (
          <UserSection user={user} miningvendor={miningvendor} />
        )}
        {((!miningvendor && !all_items_free) &&
          <CashSection current_amount={current_amount} act={act} />
        )}
        <Section
          title="Products"
          buttons={
            <Input
              value={searchText}
              placeholder="Search..."
              onInput={(e, value) => setSearchText(value)}
              mx={1}
            />
          }
        >
          <Flex>
            {!custom && searchText.length === 0 && (
              <Flex.Item>
                <Tabs vertical>
                  {categories.map((category) => (
                    <Tabs.Tab
                      key={category}
                      selected={category === selectedCategory}
                      onClick={() => setSelectedCategory(category)}
                    >
                      {category}
                    </Tabs.Tab>
                  ))}
                </Tabs>
              </Flex.Item>
            )}
            <Flex.Item grow={1} basis={0}>
              {visibleInventory.length === 0 && (
                <NoticeBox>
                  {searchText.length === 0
                    ? 'No items in this category.'
                    : 'No results found.'}
                </NoticeBox>
              )}
              <Table>
                {visibleInventory.map((product) => (
                  <VendingRow
                    key={product.name}
                    custom={custom}
                    product={product}
                    productStock={stock[product.name]}
                    user={user}
                    all_items_free={all_items_free}
                    miningvendor={miningvendor}
                    current_amount={current_amount}
                    access={access}
                    act={act}
                  />
                ))}
              </Table>
            </Flex.Item>
          </Flex>
        </Section>
      </Window.Content>
    </Window>
  );
};



