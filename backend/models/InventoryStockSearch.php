<?php

namespace app\models;

use yii\base\Model;
use yii\data\ActiveDataProvider;
use app\models\InventoryStock;

/**
 * InventoryStockSearch represents the model behind the search form of `app\models\InventoryStock`.
 */
class InventoryStockSearch extends InventoryStock
{
    public $StokKodu;
    public $warehouse_code;

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['id', 'location_id', 'siparis_id', 'goods_receipt_id'], 'integer'],
            [['pallet_barcode', 'stock_status', 'updated_at', 'expiry_date', 
            'created_at', 'StokKodu', 'shelf_code', 'sip_fisno', 'warehouse_code'], 'safe'],
            [['quantity'], 'number'],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function scenarios()
    {
        // bypass scenarios() implementation in the parent class
        return Model::scenarios();
    }

    /**
     * Creates data provider instance with search query applied
     *
     * @param array $params
     * @param string|null $formName Form name to be used into `->load()` method.
     *
     * @return ActiveDataProvider
     */
    public function search($params, $formName = null)
    {
        $query = InventoryStock::find();
        $query->joinWith('goodsReceipt');
        $query->leftJoin('shelfs', 'inventory_stock.shelf_code COLLATE utf8mb4_turkish_ci = shelfs.code COLLATE utf8mb4_turkish_ci');

        // add conditions that should always apply here

        $dataProvider = new ActiveDataProvider([
            'query' => $query,
        ]);

        $dataProvider->sort->attributes['StokKodu'] = [
            'asc' => ['inventory_stock.StokKodu' => SORT_ASC],
            'desc' => ['inventory_stock.StokKodu' => SORT_DESC],
        ];

        $this->load($params, $formName);

        if (!$this->validate()) {
            // uncomment the following line if you do not want to return any records when validation fails
            // $query->where('0=1');
            return $dataProvider;
        }

        // grid filtering conditions
        $query->andFilterWhere([
            'inventory_stock.id' => $this->id,
            'inventory_stock.location_id' => $this->location_id,
            'inventory_stock.siparis_id' => $this->siparis_id,
            'inventory_stock.goods_receipt_id' => $this->goods_receipt_id,
            'inventory_stock.quantity' => $this->quantity,
            'inventory_stock.updated_at' => $this->updated_at,
            'inventory_stock.expiry_date' => $this->expiry_date,
            'inventory_stock.created_at' => $this->created_at,
        ]);

        $query->andFilterWhere(['like', 'inventory_stock.pallet_barcode', $this->pallet_barcode])
            ->andFilterWhere(['like', 'inventory_stock.stock_status', $this->stock_status])
            ->andFilterWhere(['inventory_stock.StokKodu' => $this->StokKodu])
            ->andFilterWhere(['like', 'inventory_stock.shelf_code', $this->shelf_code]);
 
        // sales_shelf = 1 olan ürünleri hariç tut (satış rafındakiler)
        $query->andWhere(['or', ['shelfs.sales_shelf' => 0], ['shelfs.sales_shelf' => null]]);
        
        // Satış raflarını (1AB ve 1B ile başlayanlar) hariç tut
        $query->andWhere(['not like', 'inventory_stock.shelf_code', '1A%']);
        $query->andWhere(['not like', 'inventory_stock.shelf_code', '1B%']);

        // Warehouse code filtresi - seçilen warehouse'a ait raflardan (shelf) olan stokları getir
        if (!empty($this->warehouse_code)) {
            $query->andWhere(['inventory_stock.warehouse_code' => $this->warehouse_code]);
        }

        return $dataProvider;
    }
}
