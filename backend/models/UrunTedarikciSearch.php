<?php

namespace app\models;

use yii\base\Model;
use yii\data\ActiveDataProvider;
use app\models\UrunTedarikci;

/**
 * UrunTedarikciSearch represents the model behind the search form of `app\models\UrunTedarikci`.
 */
class UrunTedarikciSearch extends UrunTedarikci
{
    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['id'], 'integer'],
            [['stokkodu', 'tedarikcikodu', 'sonislemzamani', 'created_at', 'updated_at', 'tedarikciad'], 'safe'],
            [['sonfiyat'], 'number'],
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
        $query = UrunTedarikci::find();

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
            'sonfiyat' => $this->sonfiyat,
            'sonislemzamani' => $this->sonislemzamani,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ]);

        $query->andFilterWhere(['like', 'stokkodu', $this->stokkodu])
            ->andFilterWhere(['like', 'tedarikcikodu', $this->tedarikcikodu])
            ->andFilterWhere(['like', 'tedarikciad', $this->tedarikciad]);

        return $dataProvider;
    }
}
