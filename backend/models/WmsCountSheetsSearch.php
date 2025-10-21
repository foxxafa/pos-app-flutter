<?php

namespace app\models;

use yii\base\Model;
use yii\data\ActiveDataProvider;
use app\models\WmsCountSheets;

/**
 * WmsCountSheetsSearch represents the model behind the search form of `app\models\WmsCountSheets`.
 */
class WmsCountSheetsSearch extends WmsCountSheets
{
    public $branch_code;
    public $employee_username;
    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['id', 'employee_id'], 'integer'],
            [['operation_unique_id', 'sheet_number', 'warehouse_code', 'status', 'notes', 'start_date', 'complete_date', 'created_at', 'updated_at', 'doc_no', 'branch_code', 'employee_username'], 'safe'],
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
        $query = WmsCountSheets::find();
        $query->joinWith(['employee']);

        // add conditions that should always apply here
        $query->where(['wms_count_sheets.active' => 1]);

        $dataProvider = new ActiveDataProvider([
            'query' => $query,
        ]);

        // sorting for virtual attribute
        $dataProvider->sort->attributes['employee_username'] = [
            'asc' => ['employees.username' => SORT_ASC],
            'desc' => ['employees.username' => SORT_DESC],
        ];

        $this->load($params);

        if (empty($this->doc_no)) {
            $query->andWhere(['doc_no' => null]);
        }

        if (!$this->validate()) {
            // uncomment the following line if you do not want to return any records when validation fails
            // $query->where('0=1');
            return $dataProvider;
        }

        // grid filtering conditions
        $query->andFilterWhere([
            'wms_count_sheets.id' => $this->id,
            'employee_id' => $this->employee_id,
            'wms_count_sheets.start_date' => $this->start_date,
            'complete_date' => $this->complete_date,
            'wms_count_sheets.created_at' => $this->created_at,
            'wms_count_sheets.updated_at' => $this->updated_at,
        ]);

        $query->andFilterWhere(['like', 'operation_unique_id', $this->operation_unique_id])
            ->andFilterWhere(['like', 'sheet_number', $this->sheet_number])
            ->andFilterWhere(['like', 'wms_count_sheets.warehouse_code', $this->warehouse_code])
            ->andFilterWhere(['like', 'status', $this->status])
            ->andFilterWhere(['like', 'notes', $this->notes])
            ->andFilterWhere(['like', 'doc_no', $this->doc_no]);

        // filter by employee username
        $query->andFilterWhere(['like', 'employees.username', $this->employee_username]);

        return $dataProvider;
    }
}
