<?php

namespace app\models;

use yii\base\Model;
use yii\data\ActiveDataProvider;
use app\models\CashRegisters;
use app\models\Branches;

/**
 * CashRegistersSearch represents the model behind the search form of `app\models\CashRegisters`.
 */
class CashRegistersSearch extends CashRegisters
{
    public $branch_name;

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['id', 'is_active'], 'integer'],
            [['name', 'cash_out_type', 'created_at', 'updated_at', 'branch_name', 'subekodu'], 'safe'],
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
        $query = CashRegisters::find();
        $query->joinWith(['branch']);

        // add conditions that should always apply here
        $dataProvider = new ActiveDataProvider([
            'query' => $query,
            'sort' => [
                'defaultOrder' => ['id' => SORT_DESC],
                'attributes' => [
                    'id',
                    'name',
                    'subekodu' => [
                        'asc' => ['branches.name' => SORT_ASC],
                        'desc' => ['branches.name' => SORT_DESC],
                    ],
                    'cash_out_type',
                    'is_active',
                    'created_at',
                    'updated_at'
                ]
            ]
        ]);

        $this->load($params, $formName);

        if (!$this->validate()) {
            $query->where('0=1');
            return $dataProvider;
        }

        // grid filtering conditions
        $query->andFilterWhere([
            'cash_registers.id' => $this->id,
            'cash_registers.is_active' => $this->is_active,
            'cash_registers.created_at' => $this->created_at,
            'cash_registers.updated_at' => $this->updated_at,
        ]);

        $query->andFilterWhere(['like', 'cash_registers.name', $this->name])
            ->andFilterWhere(['like', 'cash_registers.cash_out_type', $this->cash_out_type])
            ->andFilterWhere(['like', 'cash_registers.subekodu', $this->subekodu])
            ->andFilterWhere(['like', 'branches.name', $this->branch_name]);

        return $dataProvider;
    }
}
