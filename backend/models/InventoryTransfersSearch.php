<?php

namespace app\models;

use yii\base\Model;
use yii\data\ActiveDataProvider;
use app\models\InventoryTransfers;

/**
 * InventoryTransfersSearch represents the model behind the search form of `app\models\InventoryTransfers`.
 */
class InventoryTransfersSearch extends InventoryTransfers
{
    public $StokKodu;
    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['id', 'from_location_id', 'to_location_id', 'employee_id', 'siparis_id', 'goods_receipt_id'], 'integer'],
            [['urun_key', 'from_pallet_barcode', 'pallet_barcode', 'transfer_date', 'delivery_note_number', 'created_at', 'updated_at', 'StokKodu', 'from_shelf', 'to_shelf', 'sip_fisno'], 'safe'],
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
        $query = InventoryTransfers::find();
        $query->joinWith(['urun']);

        // add conditions that should always apply here

        $dataProvider = new ActiveDataProvider([
            'query' => $query,
        ]);

        $dataProvider->sort->attributes['StokKodu'] = [
            'asc' => ['urunler.StokKodu' => SORT_ASC],
            'desc' => ['urunler.StokKodu' => SORT_DESC],
        ];

        $this->load($params, $formName);

        if (!$this->validate()) {
            // uncomment the following line if you do not want to return any records when validation fails
            // $query->where('0=1');
            return $dataProvider;
        }

        // grid filtering conditions
        $query->andFilterWhere([
            'id' => $this->id,
            'from_location_id' => $this->from_location_id,
            'to_location_id' => $this->to_location_id,
            'quantity' => $this->quantity,
            'employee_id' => $this->employee_id,
            'transfer_date' => $this->transfer_date,
            'siparis_id' => $this->siparis_id,
            'goods_receipt_id' => $this->goods_receipt_id,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ]);

        $query->andFilterWhere(['like', 'urun_key', $this->urun_key])
            ->andFilterWhere(['like', 'from_pallet_barcode', $this->from_pallet_barcode])
            ->andFilterWhere(['like', 'pallet_barcode', $this->pallet_barcode])
            ->andFilterWhere(['like', 'delivery_note_number', $this->delivery_note_number])
            ->andFilterWhere(['like', 'urunler.StokKodu', $this->StokKodu])
            ->andFilterWhere(['like', 'inventory_transfers.StokKodu', $this->StokKodu])
            ->andFilterWhere(['like', 'from_shelf', $this->from_shelf])
            ->andFilterWhere(['like', 'to_shelf', $this->to_shelf])
            ->andFilterWhere(['like', 'sip_fisno', $this->sip_fisno]);

        return $dataProvider;
    }
}
