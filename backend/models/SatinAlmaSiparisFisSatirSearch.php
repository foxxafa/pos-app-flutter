<?php

namespace app\models;

use yii\base\Model;
use yii\data\ActiveDataProvider;
use app\models\SatinAlmaSiparisFisSatir;

/**
 * SatinAlmaSiparisFisSatirSearch represents the model behind the search form of `app\models\SatinAlmaSiparisFisSatir`.
 */
class SatinAlmaSiparisFisSatirSearch extends SatinAlmaSiparisFisSatir
{
    // İlişkili tablo alanları için public özellikler ekleyin
    public $urunAdi;
    public $barkod;
    public $marka;
    public $grup;
    public $layer;
    public $po_id;
    public $StokKodu;
    public $tedarikci_adi;

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['siparis_id', 'urun_id', 'miktar', 'son_7_gun', 'tedarikci_fis_id', 'layer', 'type'], 'default', 'value' => null],
            [['siparis_id', 'urun_id', 'tedarikci_fis_id', 'layer', 'status', 'good_received', 'type', 'aylık_satis_tahmin'], 'integer'],
            [['miktar', 'son_7_gun', 'one_week', 'two_week', 'three_week', 'one_month', 'two_months', 'three_months', 'retro', 'cost', 'BirimFiyat', 'ToplamTutar'], 'number'],
            [['urun_id'], 'exist', 'skipOnError' => true, 'targetClass' => Urunler::class, 'targetAttribute' => ['urun_id' => 'UrunId']],
            [['siparis_id'], 'exist', 'skipOnError' => true, 'targetClass' => SatinAlmaSiparisFis::class, 'targetAttribute' => ['siparis_id' => 'id']],
            [['tedarikci_fis_id'], 'exist', 'skipOnError' => true, 'targetClass' => TedarikciSiparisFis::class, 'targetAttribute' => ['tedarikci_fis_id' => 'id']],
            [['urunAdi', 'barkod', 'marka', 'grup', 'invoice', 'birim', 'notes', 'tedarikci_kodu', 'po_id', 'StokKodu','tedarikci_adi', 'updated_at'], 'safe'],
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
     *
     * @return ActiveDataProvider
     */
    public function search($params)
    {
        $query = SatinAlmaSiparisFisSatir::find()
            ->joinWith(['urun'])
            ->joinWith(['urun.marka'])
            ->joinWith('tedarikci')
            ->where(['urunler.aktif' => 1]);
            

        $dataProvider = new ActiveDataProvider([
            'query' => $query,
            'sort' => [
                'defaultOrder' => ['id' => SORT_DESC],
            ],
        ]);

        // İlişkili tablo alanları için sıralama kuralları
        $dataProvider->sort->attributes['id'] = [
            'asc' => ['satin_alma_siparis_fis_satir.id' => SORT_ASC],
            'desc' => ['satin_alma_siparis_fis_satir.id' => SORT_DESC],
        ];
        $dataProvider->sort->attributes['urunAdi'] = [
            'asc' => ['urunler.UrunAdi' => SORT_ASC],
            'desc' => ['urunler.UrunAdi' => SORT_DESC],
        ];

        $dataProvider->sort->attributes['tedarikci_adi'] = [
            'asc' => ['tedarikci.tedarikci_adi' => SORT_ASC],
            'desc' => ['tedarikci.tedarikci_adi' => SORT_DESC],
        ];

        $dataProvider->sort->attributes['marka'] = [
            'asc' => ['marka.adi' => SORT_ASC],
            'desc' => ['marka.adi' => SORT_DESC],
        ];

        $dataProvider->sort->attributes['grup'] = [
            'asc' => ['urunler.Grup' => SORT_ASC],
            'desc' => ['urunler.Grup' => SORT_DESC],
        ];

        $dataProvider->sort->attributes['StokKodu'] = [
            'asc' => ['urunler.StokKodu' => SORT_ASC],
            'desc' => ['urunler.StokKodu' => SORT_DESC],
        ];

        $dataProvider->sort->attributes['po_id'] = [
            'asc' => ['satin_alma_siparis_fis_satir.po_id' => SORT_ASC],
            'desc' => ['satin_alma_siparis_fis_satir.po_id' => SORT_DESC],
        ];

        $dataProvider->sort->attributes['BirimFiyat'] = [
            'asc' => ['satin_alma_siparis_fis_satir.BirimFiyat' => SORT_ASC],
            'desc' => ['satin_alma_siparis_fis_satir.BirimFiyat' => SORT_DESC],
        ];

        $dataProvider->sort->attributes['ToplamTutar'] = [
            'asc' => ['satin_alma_siparis_fis_satir.ToplamTutar' => SORT_ASC],
            'desc' => ['satin_alma_siparis_fis_satir.ToplamTutar' => SORT_DESC],
        ];

        $dataProvider->sort->attributes['status'] = [
            'asc' => ['satin_alma_siparis_fis_satir.status' => SORT_ASC],
            'desc' => ['satin_alma_siparis_fis_satir.status' => SORT_DESC],
        ];

        $dataProvider->sort->attributes['aylık_satis_tahmin'] = [
            'asc' => ['satin_alma_siparis_fis_satir.aylık_satis_tahmin' => SORT_ASC],
            'desc' => ['satin_alma_siparis_fis_satir.aylık_satis_tahmin' => SORT_DESC],
        ];

        $this->load($params);

        if (!$this->validate()) {
            return $dataProvider;
        }

        // Filtreleme koşulları
        $query->andFilterWhere([
            'satin_alma_siparis_fis_satir.id' => $this->id, // Tablo adını belirtin
            'siparis_id' => $this->siparis_id,
            'urun_id' => $this->urun_id,
            'miktar' => $this->miktar,
            'son_7_gun' => $this->son_7_gun,
            'tedarikci_fis_id' => $this->tedarikci_fis_id,
            'layer' => $this->layer,
            'retro' => $this->retro,
            'cost' => $this->cost,
            'satin_alma_siparis_fis_satir.BirimFiyat' => $this->BirimFiyat,
            'satin_alma_siparis_fis_satir.ToplamTutar' => $this->ToplamTutar,
            'satin_alma_siparis_fis_satir.status' => $this->status,
            'satin_alma_siparis_fis_satir.good_received' => $this->good_received,
            'satin_alma_siparis_fis_satir.type' => $this->type,
            'satin_alma_siparis_fis_satir.aylık_satis_tahmin' => $this->aylık_satis_tahmin,
        ]);

        if (!empty($this->updated_at)) {
            $query->andFilterWhere(['like', 'DATE(satin_alma_siparis_fis_satir.updated_at)', $this->updated_at]);
        }

        // İlişkili tablo alanları için filtreleme
        $query->andFilterWhere(['like', 'urunler.UrunAdi', $this->urunAdi])
              ->andFilterWhere(['like', 'urunler.StokKodu', $this->StokKodu])
              ->andFilterWhere(['like', 'urunler.Barcode1', $this->barkod])
              ->andFilterWhere(['like', 'marka.adi', $this->marka]) // marka tablosundan filtrele
              ->andFilterWhere(['like', 'satin_alma_siparis_fis_satir.po_id', $this->po_id])
              ->andFilterWhere(['like', 'satin_alma_siparis_fis_satir.invoice', $this->invoice])
              ->andFilterWhere(['like', 'satin_alma_siparis_fis_satir.birim', $this->birim])
              ->andFilterWhere(['like', 'satin_alma_siparis_fis_satir.notes', $this->notes])
              ->andFilterWhere(['like', 'satin_alma_siparis_fis_satir.tedarikci_kodu', $this->tedarikci_kodu])
              ->andFilterWhere(['like', 'tedarikci.tedarikci_adi', $this->tedarikci_adi])
              ->andFilterWhere(['like', 'urunler.Grup', $this->grup]);

        return $dataProvider;
    }

    public function getUrun()
    {
        return $this->hasOne(Urunler::class, ['UrunId' => 'urun_id']);
    }
}
