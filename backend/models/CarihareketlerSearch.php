<?php

namespace app\models;

use yii\base\Model;
use yii\data\ActiveDataProvider;
use app\models\Carihareketler;

/**
 * CarihareketlerSearch represents the model behind the search form of `app\models\Carihareketler`.
 */
class CarihareketlerSearch extends Carihareketler
{
    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['HareketId', 'cash_session_id'], 'integer'],
            [['HareketTuru', 'HareketTarihi', 'CariId', 'FisId', 'ParaBirimi', 'Aciklama', 'OdemeYontemi', 'IslemYapan', 'OlusturulmaTarihi', 'GuncellenmeTarihi', 'carikod'], 'safe'],
            [['Tutar'], 'number'],
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
        $query = Carihareketler::find();

        // add conditions that should always apply here

        $dataProvider = new ActiveDataProvider([
            'query' => $query,
        ]);

        $this->load($params, $formName);

        if (!$this->validate()) {
            // uncomment the following line if you do not want to return any records when validation fails
            // $query->where('0=1');
            return $dataProvider;
        }

        // grid filtering conditions
        $query->andFilterWhere([
            'HareketId' => $this->HareketId,
            'HareketTarihi' => $this->HareketTarihi,
            'Tutar' => $this->Tutar,
            'cash_session_id' => $this->cash_session_id,
            'OlusturulmaTarihi' => $this->OlusturulmaTarihi,
            'GuncellenmeTarihi' => $this->GuncellenmeTarihi,
        ]);

        $query->andFilterWhere(['like', 'HareketTuru', $this->HareketTuru])
            ->andFilterWhere(['like', 'CariId', $this->CariId])
            ->andFilterWhere(['like', 'FisId', $this->FisId])
            ->andFilterWhere(['like', 'ParaBirimi', $this->ParaBirimi])
            ->andFilterWhere(['like', 'Aciklama', $this->Aciklama])
            ->andFilterWhere(['like', 'OdemeYontemi', $this->OdemeYontemi])
            ->andFilterWhere(['like', 'IslemYapan', $this->IslemYapan])
            ->andFilterWhere(['like', 'carikod', $this->carikod]);

        return $dataProvider;
    }
}
