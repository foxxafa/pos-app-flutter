<?php

namespace app\models;

use yii\base\Model;
use yii\data\ActiveDataProvider;
use app\models\Musteriler;

/**
 * MusterilerSearch represents the model behind the search form of `app\models\Musteriler`.
 */
class MusterilerSearch extends Musteriler
{
    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['MusteriId'], 'integer'],
            [['Unvan', 'VergiNo', 'VergiDairesi', 'anaadreskey', 'Adres', 'Telefon', 'Email', 'Kod', 'created_at', 'updated_at', 'postcode', 'city', 'contact', 'mobile', '_key', 'satiselemani', 'EOID', 'FID'], 'safe'],
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
        $query = Musteriler::find()->where(['Aktif'=>1]);

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
            'MusteriId' => $this->MusteriId
        ]);

        $query->andFilterWhere(['like', 'Unvan', $this->Unvan])
            ->andFilterWhere(['like', 'VergiNo', $this->VergiNo])
            ->andFilterWhere(['like', 'VergiDairesi', $this->VergiDairesi])
            ->andFilterWhere(['like', 'anaadreskey', $this->anaadreskey])
            ->andFilterWhere(['like', 'Adres', $this->Adres])
            ->andFilterWhere(['like', 'Telefon', $this->Telefon])
            ->andFilterWhere(['like', 'Email', $this->Email])
            ->andFilterWhere(['like', 'Kod', $this->Kod])
            ->andFilterWhere(['like', 'created_at', $this->created_at])
            ->andFilterWhere(['like', 'updated_at', $this->updated_at])
            ->andFilterWhere(['like', 'postcode', $this->postcode])
            ->andFilterWhere(['like', 'city', $this->city])
            ->andFilterWhere(['like', 'contact', $this->contact])
            ->andFilterWhere(['like', 'mobile', $this->mobile])
            ->andFilterWhere(['like', '_key', $this->_key])
            ->andFilterWhere(['like', 'satiselemani', $this->satiselemani])
            ->andFilterWhere(['like', 'EOID', $this->EOID])
            ->andFilterWhere(['like', 'FID', $this->FID]);

        return $dataProvider;
    }
}
