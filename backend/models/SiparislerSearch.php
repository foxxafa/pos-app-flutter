<?php

namespace app\models;

use yii\base\Model;
use yii\data\ActiveDataProvider;
use app\models\Siparisler;

/**
 * SiparislerSearch represents the model behind the search form of `app\models\Siparisler`.
 */
class SiparislerSearch extends Siparisler
{
    /**
     * Date range filtering properties
     */
    public $customer_unvan;
    public $customer_postcode;


    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['id', '_owner', 'delivery_id'], 'integer'],
            [['net', 'netdvz', 'odenen_tutar', 'teslimatkalanmiktar', 'teslimatmiktar', 'toplam', 'toplamanamiktar', 'toplamara', 'toplamaradvz', 'toplamdvz', 'toplamindirim', 'toplamindirimdvz', 'toplamkdv', 'toplamkdvdvz', 'toplamkdvtevkifati', 'toplamkdvtevkifatidvz', 'toplammasraf', 'toplammasrafdvz', 'toplammiktar', 'toplammiktarrafyerli', 'toplamov', 'toplamovdvz'], 'number'],
            [['tarih', '_cdate', '_date', '__sourcesubeadi', '__sourcedepoadi', '__format', '_key', '_key_satiselemanlari', '__carikodu', '_key_scf_satiselemani', '_key_sis_firma', '_user', 'aciklama', '_serial', 'aciklama2', 'aciklama3', 'adsoyad', 'ekleyenkullaniciadi', 'fisno', 'gorusmenotu', 'kargofirma', 'kargogonderimsaati', 'kargogonderimtarihi', 'kullaniciadi', 'onay', 'onay_txt', 'satiselemani', 'sevkadresi', 'sevkadresi1', 'sevkadresi2', 'sevkadresi3', 'sevkadresi_adi', 'siparisdurum', 'sipariskalemturleri', 'sipteslimattarihi', 'tamamisevkedildi', 'teslimat_adres1', 'teslimat_adsoyad', 'teslimattarihi', 'turu', 'turuack', 'subekodu', 'depokodu', 'customer_unvan', 'customer_postcode'], 'safe'],
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
        $query = Siparisler::find();
        $query->joinWith(['musteri']);

        // add conditions that should always apply here
        $dataProvider = new ActiveDataProvider([
            'query' => $query,
        ]);

        $dataProvider->sort->attributes['customer_unvan'] = [
            'asc' => ['musteriler.Unvan' => SORT_ASC],
            'desc' => ['musteriler.Unvan' => SORT_DESC],
        ];

        $dataProvider->sort->attributes['customer_postcode'] = [
            'asc' => ['musteriler.postcode' => SORT_ASC],
            'desc' => ['musteriler.postcode' => SORT_DESC],
        ];

        $this->load($params);

        if (!$this->validate()) {
            // uncomment the following line if you do not want to return any records when validation fails
            // $query->where('0=1');
            return $dataProvider;
        }

        // grid filtering conditions
        $query->andFilterWhere([
            'id' => $this->id,
            '_owner' => $this->_owner,
            'delivery_id' => $this->delivery_id,
            'net' => $this->net,
            'netdvz' => $this->netdvz,
            'odenen_tutar' => $this->odenen_tutar,
            'teslimatkalanmiktar' => $this->teslimatkalanmiktar,
            'teslimatmiktar' => $this->teslimatmiktar,
            'toplam' => $this->toplam,
            'toplamanamiktar' => $this->toplamanamiktar,
            'toplamara' => $this->toplamara,
            'toplamaradvz' => $this->toplamaradvz,
            'toplamdvz' => $this->toplamdvz,
            'toplamindirim' => $this->toplamindirim,
            'toplamindirimdvz' => $this->toplamindirimdvz,
            'toplamkdv' => $this->toplamkdv,
            'toplamkdvdvz' => $this->toplamkdvdvz,
            'toplamkdvtevkifati' => $this->toplamkdvtevkifati,
            'toplamkdvtevkifatidvz' => $this->toplamkdvtevkifatidvz,
            'toplammasraf' => $this->toplammasraf,
            'toplammasrafdvz' => $this->toplammasrafdvz,
            'toplammiktar' => $this->toplammiktar,
            'toplammiktarrafyerli' => $this->toplammiktarrafyerli,
            'toplamov' => $this->toplamov,
            'toplamovdvz' => $this->toplamovdvz,
            '_cdate' => $this->_cdate,
            '_date' => $this->_date,
        ]);
        
        // Date range filtering for tarih
        if (!empty($this->tarih)) {
            $query->andFilterWhere(['tarih' => $this->tarih]);
        }

        $query->andFilterWhere(['like', '__sourcesubeadi', $this->__sourcesubeadi])
            ->andFilterWhere(['like', '__sourcedepoadi', $this->__sourcedepoadi])
            ->andFilterWhere(['like', '__format', $this->__format])
            ->andFilterWhere(['like', '_key', $this->_key])
            ->andFilterWhere(['like', '_key_satiselemanlari', $this->_key_satiselemanlari])
            ->andFilterWhere(['like', '__carikodu', $this->__carikodu])

            ->andFilterWhere(['like', '_key_scf_satiselemani', $this->_key_scf_satiselemani])
            ->andFilterWhere(['like', '_key_sis_firma', $this->_key_sis_firma])
            ->andFilterWhere(['like', '_user', $this->_user])
            ->andFilterWhere(['like', 'aciklama', $this->aciklama])
            ->andFilterWhere(['like', '_serial', $this->_serial])
            ->andFilterWhere(['like', 'aciklama2', $this->aciklama2])
            ->andFilterWhere(['like', 'aciklama3', $this->aciklama3])
            ->andFilterWhere(['like', 'adsoyad', $this->adsoyad])
            ->andFilterWhere(['like', 'ekleyenkullaniciadi', $this->ekleyenkullaniciadi])
            ->andFilterWhere(['like', 'fisno', $this->fisno])
            ->andFilterWhere(['like', 'gorusmenotu', $this->gorusmenotu])
            ->andFilterWhere(['like', 'kargofirma', $this->kargofirma])
            ->andFilterWhere(['like', 'kargogonderimsaati', $this->kargogonderimsaati])
            ->andFilterWhere(['like', 'kargogonderimtarihi', $this->kargogonderimtarihi])
            ->andFilterWhere(['like', 'kullaniciadi', $this->kullaniciadi])
            ->andFilterWhere(['like', 'onay', $this->onay])
            ->andFilterWhere(['like', 'onay_txt', $this->onay_txt])
            ->andFilterWhere(['like', 'siparisler.satiselemani', $this->satiselemani])
            ->andFilterWhere(['like', 'sevkadresi', $this->sevkadresi])
            ->andFilterWhere(['like', 'sevkadresi1', $this->sevkadresi1])
            ->andFilterWhere(['like', 'sevkadresi2', $this->sevkadresi2])
            ->andFilterWhere(['like', 'sevkadresi3', $this->sevkadresi3])
            ->andFilterWhere(['like', 'sevkadresi_adi', $this->sevkadresi_adi])
            ->andFilterWhere(['like', 'siparisdurum', $this->siparisdurum])
            ->andFilterWhere(['like', 'sipariskalemturleri', $this->sipariskalemturleri])
            ->andFilterWhere(['like', 'sipteslimattarihi', $this->sipteslimattarihi])
            ->andFilterWhere(['like', 'tamamisevkedildi', $this->tamamisevkedildi])
            ->andFilterWhere(['like', 'teslimat_adres1', $this->teslimat_adres1])
            ->andFilterWhere(['like', 'teslimat_adsoyad', $this->teslimat_adsoyad])
            ->andFilterWhere(['like', 'teslimattarihi', $this->teslimattarihi])
            ->andFilterWhere(['like', 'turu', $this->turu])
            ->andFilterWhere(['like', 'turuack', $this->turuack])
            ->andFilterWhere(['like', 'subekodu', $this->subekodu])
            ->andFilterWhere(['like', 'depokodu', $this->depokodu])
            ->andFilterWhere(['like', 'musteriler.Unvan', $this->customer_unvan])
            ->andFilterWhere(['like', 'musteriler.postcode', $this->customer_postcode]);

        return $dataProvider;
    }
} 