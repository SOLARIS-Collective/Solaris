export type Data = {
  access: boolean;
  all_items_free: boolean;
  miningvendor: boolean;
  user: User;
  categories: string[];
  product_records: ProductRecord[];
  coin_records: ProductRecord[];
  hidden_records: ProductRecord[];
  stock: [];
  current_amount: number;
  vending_machine_input: any[];
  extended_inventory: boolean;
};

export type ProductRecord = {
  path: string;
  name: string;
  price: number;
  max_amount: number;
  ref: string;
  premium?: boolean;
  category: string;
};

export type User = {
  cash: number;
  points: number;
  name: string;
  job: string;
};
