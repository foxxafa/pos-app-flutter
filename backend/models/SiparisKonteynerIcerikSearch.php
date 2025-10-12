<?php

namespace app\models;

use yii\base\Model;
use yii\data\ActiveDataProvider;
use app\models\SiparisKonteynerIcerik;

/**
 * SiparisKonteynerIcerikSearch represents the model behind the search form of `app\models\SiparisKonteynerIcerik`.
 */
class SiparisKonteynerIcerikSearch extends SiparisKonteynerIcerik
{
    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['id', 'siparis_konteyner_id', 'siparis_satir_id', 'palet_sayisi'], 'integer'],
            [['branch_code', 'created_at', 'updated_at'], 'safe'],
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
        $query = SiparisKonteynerIcerik::find();

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
            'id' => $this->id,
            'siparis_konteyner_id' => $this->siparis_konteyner_id,
            'siparis_satir_id' => $this->siparis_satir_id,
            'palet_sayisi' => $this->palet_sayisi,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ]);

        $query->andFilterWhere(['like', 'branch_code', $this->branch_code]);

        return $dataProvider;
    }
}
