<?php

namespace app\models;

use yii\base\Model;
use yii\data\ActiveDataProvider;
use app\models\SatinAlmaSiparisFis;

/**
 * SatinAlmaSiparisFisSearch represents the model behind the search form of `app\models\SatinAlmaSiparisFis`.
 */
class SatinAlmaSiparisFisSearch extends SatinAlmaSiparisFis
{
    public $tarih_search;
    public $created_at_range;
    
    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['id', 'gun', 'delivery', 'branch_code', 'warehouse_code', 'status'], 'integer'],
            [['tarih', 'notlar', 'user', 'created_at', 'updated_at', 'po_id', 'tarih_search', 'created_at_range'], 'safe'],
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
        $query = SatinAlmaSiparisFis::find();

        $dataProvider = new ActiveDataProvider([
            'query' => $query,
            'sort' => [
                'defaultOrder' => ['id' => SORT_DESC],
            ],
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
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
            'gun' => $this->gun,
            'delivery' => $this->delivery,
            'branch_code' => $this->branch_code,
            'warehouse_code' => $this->warehouse_code,
            'status' => $this->status,
        ]);

        $query->andFilterWhere(['like', 'notlar', $this->notlar])
            ->andFilterWhere(['like', 'user', $this->user])
            ->andFilterWhere(['like', 'po_id', $this->po_id]);

        // Tarih arama - kısmi tarih girişi için LIKE kullan
        if (!empty($this->tarih_search)) {
            $query->andFilterWhere(['like', 'DATE_FORMAT(tarih, "%d.%m.%Y")', $this->tarih_search]);
        }

        // Created at aralığı filtreleme
        if (!empty($this->created_at_range)) {
            $dates = explode(' - ', $this->created_at_range);
            if (count($dates) == 2) {
                $query->andFilterWhere(['>=', 'created_at', $dates[0]])
                      ->andFilterWhere(['<=', 'created_at', $dates[1]]);
            }
        }

        return $dataProvider;
    }
}
