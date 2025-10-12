<?php

namespace app\models;

use yii\base\Model;
use yii\data\ActiveDataProvider;
use app\models\Urunler;

/**
 * UrunlerSearch represents the model behind the search form of `app\models\Urunler`.
 */
class UrunlerSearch extends Urunler
{
    /**
     * {@inheritdoc}
     */
    public $tedarikci_kodu;
    public $branch_code;
    public $warehouse_code;

    public function rules()
    {
        return [
            [['UrunId', 'BirimKey1', 'BirimKey2', 'aktif', 'qty', 'rafno', 'rafomru', 'Palet', 'Layer'], 'integer'],
            [['StokKodu', 'UrunAdi', 'Barcode1', 'Barcode2', 'Barcode3', 'Birim1', 'Birim2', 
              'created_at', 'updated_at', 'Barcode4', 'size', 'HSCode', 'rafkoridor', 'rafkat',
              'marka_id', 'kategori_id', 'grup_id', 'tedarikci_kodu', 'branch_code', 'warehouse_code',
              'marka.marka', 'kategori.kategori', 'grup.grup','mcat','cat','subcat','marka'], 'safe'],
            [['AdetFiyati', 'KutuFiyati', 'Pm1', 'Pm2', 'Pm3', 'Vat', 'unitkg'], 'number'],
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
        $query = Urunler::find()
            ->joinWith(['marka', 'grup', 'kategori'])
            ->joinWith(['tedarikci t'])
            ->joinWith(['tedarikci.tedarikci td']);

        $dataProvider = new ActiveDataProvider([
            'query' => $query,
        ]);

        $this->load($params, $formName);

        if (!$this->validate()) {
            return $dataProvider;
        }

        // grid filtering conditions
        $query->andFilterWhere([
            'urunler.UrunId' => $this->UrunId,
            'urunler.AdetFiyati' => $this->AdetFiyati,
            'urunler.KutuFiyati' => $this->KutuFiyati,
            'urunler.Pm1' => $this->Pm1,
            'urunler.Pm2' => $this->Pm2,
            'urunler.Pm3' => $this->Pm3,
            'urunler.Vat' => $this->Vat,
            'urunler.BirimKey1' => $this->BirimKey1,
            'urunler.BirimKey2' => $this->BirimKey2,
            'urunler.created_at' => $this->created_at,
            'urunler.updated_at' => $this->updated_at,
            'urunler.aktif' => $this->aktif,
            'urunler.qty' => $this->qty,
            'urunler.unitkg' => $this->unitkg,
            'urunler.rafno' => $this->rafno,
            'urunler.rafomru' => $this->rafomru,
            'urunler.Palet' => $this->Palet,
            'urunler.Layer' => $this->Layer,
        ]);

        $query->andFilterWhere(['like', 'urunler.StokKodu', $this->StokKodu])
            ->andFilterWhere(['like', 'urunler.UrunAdi', $this->UrunAdi])
            ->andFilterWhere(['like', 'urunler.Barcode1', $this->Barcode1])
            ->andFilterWhere(['like', 'urunler.Barcode2', $this->Barcode2])
            ->andFilterWhere(['like', 'urunler.Barcode3', $this->Barcode3])
            ->andFilterWhere(['like', 'urunler.Birim1', $this->Birim1])
            ->andFilterWhere(['like', 'urunler.Birim2', $this->Birim2])
            ->andFilterWhere(['like', 'urunler.Barcode4', $this->Barcode4])
            ->andFilterWhere(['like', 'urunler.size', $this->size])
            ->andFilterWhere(['like', 'urunler.HSCode', $this->HSCode])
            ->andFilterWhere(['like', 'urunler.rafkoridor', $this->rafkoridor])
            ->andFilterWhere(['like', 'urunler.rafkat', $this->rafkat])
            ->andFilterWhere(['like', 'kategori.adi', $this->kategori_id])
            ->andFilterWhere(['like', 'marka.adi', $this->marka_id])
            ->andFilterWhere(['like', 'grup.adi', $this->grup_id])
            ->andFilterWhere(['like', 'urunler.mcat', $this->mcat])
            ->andFilterWhere(['like', 'urunler.cat', $this->cat])
            ->andFilterWhere(['like', 'urunler.subcat', $this->subcat])
            ->andFilterWhere(['like', 'td.tedarikci_adi', $this->tedarikci_kodu]);

        // Brand filter: search by related marka.adi OR fallback urunler.marka string
        if (!empty($this->marka)) {
            $query->andWhere(['or',
                ['like', 'marka.adi', $this->marka],
                ['like', 'urunler.marka', $this->marka],
            ]);
        }

        return $dataProvider;
    }
}
