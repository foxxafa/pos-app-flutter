<?php

namespace app\models;

use yii\base\Model;
use yii\data\ActiveDataProvider;
use app\models\TedarikciSiparisFis;

/**
 * TedarikciSiparisFisSearch represents the model behind the search form of `app\models\TedarikciSiparisFis`.
 */
class TedarikciSiparisFisSearch extends TedarikciSiparisFis
{
    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['id', 'tedarikci_id'], 'integer'],
            [['stok_kodu', 'tarih', 'user', 'created_at', 'updated_at'], 'safe'],
            [['miktar'], 'number'],
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
        $query = TedarikciSiparisFis::find();

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
            'miktar' => $this->miktar,
            'tedarikci_id' => $this->tedarikci_id,
            'tarih' => $this->tarih,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ]);

        $query->andFilterWhere(['like', 'stok_kodu', $this->stok_kodu])
            ->andFilterWhere(['like', 'user', $this->user]);

        return $dataProvider;
    }
}
