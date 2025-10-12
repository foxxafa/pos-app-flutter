<?php

namespace app\models;

use yii\base\Model;
use yii\data\ActiveDataProvider;
use app\models\Iadefisleri;

/**
 * IadefisleriSearch represents the model behind the search form of `app\models\Iadefisleri`.
 */
class IadefisleriSearch extends Iadefisleri
{
    /**
     * {@inheritdoc}
     */
    public $cashSessionState = 'any'; // 'null' | 'not_null' | 'any'
    public function rules()
    {
        return [
            [['FisId', 'SyncStatus', 'diakey', 'payed', 'cash_session_id'], 'integer'],
            [['FisNo', 'Fistarihi', 'MusteriId', 'OdemeTuru', 'status', 'LastSyncTime', 'tur', 'aciklama', 'iadenedeni', 'satispersoneli', 'tillname'], 'safe'],
            [['Toplamtutar', 'NakitOdeme', 'KartOdeme'], 'number'],
            [['cashSessionState'], 'in', 'range' => ['null', 'not_null', 'any']],
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
    $query = Iadefisleri::find();

    // cash_session filtresi controller tarafından belirlenir
    if ($this->cashSessionState === 'null') {
        $query->andWhere('cash_session_id IS NULL');
    } elseif ($this->cashSessionState === 'not_null') {
        $query->andWhere('cash_session_id IS NOT NULL');
    }

    // Mevcut kural korunuyor: sadece tur NULL olanlar (işlenmemiş iadeler)
    $query->andWhere(['tur' => null]);

    $dataProvider = new ActiveDataProvider([
        'query' => $query,
    ]);

    $this->load($params, $formName);

    if (!$this->validate()) {
        return $dataProvider;
    }

    // grid filtering conditions
    $query->andFilterWhere([
        'FisId' => $this->FisId,
        'Fistarihi' => $this->Fistarihi,
        'Toplamtutar' => $this->Toplamtutar,
        'NakitOdeme' => $this->NakitOdeme,
        'KartOdeme' => $this->KartOdeme,
        'SyncStatus' => $this->SyncStatus,
        'LastSyncTime' => $this->LastSyncTime,
        'diakey' => $this->diakey,
        'payed' => $this->payed,
        'cash_session_id' => $this->cash_session_id,
    ]);

    $query->andFilterWhere(['like', 'FisNo', $this->FisNo])
        ->andFilterWhere(['like', 'MusteriId', $this->MusteriId])
        ->andFilterWhere(['like', 'OdemeTuru', $this->OdemeTuru])
        ->andFilterWhere(['like', 'status', $this->status])
        ->andFilterWhere(['like', 'aciklama', $this->aciklama])
        ->andFilterWhere(['like', 'iadenedeni', $this->iadenedeni])
        ->andFilterWhere(['like', 'tur', $this->tur])
        ->andFilterWhere(['like', 'satispersoneli', $this->satispersoneli])
        ->andFilterWhere(['like', 'tillname', $this->tillname]);

    return $dataProvider;
}
}
