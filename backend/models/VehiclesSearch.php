<?php

namespace app\models;

use yii\base\Model;
use yii\data\ActiveDataProvider;
use app\models\Vehicles;

/**
 * VehiclesSearch represents the model behind the search form of `app\models\Vehicles`.
 */
class VehiclesSearch extends Vehicles
{
    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['id', 'wheel_count', 'vehicle_type_id', 'is_active', 'user_id'], 'integer'],
            [['license_plate', 'brand', 'model', 'manufacture_year', 'color', 'created', 'updated'], 'safe'],
            [['weight_limit_kg'], 'number'],
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
        $query = Vehicles::find();

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
            'wheel_count' => $this->wheel_count,
            'weight_limit_kg' => $this->weight_limit_kg,
            'vehicle_type_id' => $this->vehicle_type_id,
            'manufacture_year' => $this->manufacture_year,
            'is_active' => $this->is_active,
            'created' => $this->created,
            'updated' => $this->updated,
            'user_id' => $this->user_id,
        ]);

        $query->andFilterWhere(['like', 'license_plate', $this->license_plate])
            ->andFilterWhere(['like', 'brand', $this->brand])
            ->andFilterWhere(['like', 'model', $this->model])
            ->andFilterWhere(['like', 'color', $this->color]);

        return $dataProvider;
    }
}
