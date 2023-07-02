<?php

namespace Drupal\manage_quotes;

use Drupal\Core\Logger\LoggerChannelTrait;
use Drupal\paragraphs\Entity\Paragraph;

class ValidateQuotes {
    use LoggerChannelTrait;

    /**
     * The logger.
     *
     * @var \Drupal\Core\Logger\LoggerChannelInterface
     */
    protected $logger;

    /**
     * The quotes without filter
     *
     * @var array
     */
    protected $unfiltered_quotes;

    /**
     * The search term
     *
     * @var string
     */
    protected $search_term;

    /**
     * The current quote that conatains the paragraph 
     *
     * @var string
     */
    protected $current_quote;

    /**
     * New array of quotes that will be sent to the view result
     *
     * @var array
     */
    protected $valid_quotes;

    /**
     * Quotes validator constructor 
     *
     * @param array $unfiltered_quotes
     * @param string $search_term
     */
    public function __construct(array $unfiltered_quotes, string $search_term) {
        $this->setUnfilteredQuotes($unfiltered_quotes);
        $this->setSearchTerm($search_term);
        $this->validate($this->getUnfilteredQuotes());
    }

    /**
     * Set valid quotes
     *
     * @param array $valid_quotes
     * @return void
     */
    private function setValidQuotes(array $valid_quotes): void {
        $this->valid_quotes = $valid_quotes;
    }

    /**
     * Get the valid quotes
     *
     * @return array
     */
    public function getValidQuotes(): array {
        return $this->valid_quotes;
    }

    /**
     * Set search term used in the view form
     *
     * @param [type] $search_term
     * @return void
     */
    private function setSearchTerm($search_term): void {
        $this->search_term = $search_term;
    }

    /**
     * get the term
     *
     * @return string
     */
    private function getSearchTerm(): string {
        return $this->search_term;
    }

    /**
     * Set the unfiltered quotes attribute
     *
     * @param [type] $unfiltered_quotes
     * @return void
     */
    private function setUnfilteredQuotes($unfiltered_quotes): void {
        $this->unfiltered_quotes = $unfiltered_quotes;
    }

    /**
     * Get the unfiltered quotes attribute
     *
     * @return array
     */
    private function getUnfilteredQuotes(): array {
        return $this->unfiltered_quotes;
    }
   
    /**
     * Use it to unset unfiltered array
     *
     * @param string $current_quote
     * @return void
     */
    private function setCurrentQuote(string $current_quote): void {
        $this->current_quote = $current_quote;
    }

    /**
     * get the current quote to use it in the unset
     *
     * @return string
     */
    private function getCurrentQuote(): string {
        return $this->current_quote;
    }

    /**
     * Get treated string as text
     *
     * @param Paragraph $paragraph
     * @return string
     */
    private function getQuoteText(Paragraph $paragraph): string {
        $field_quote_text = $paragraph->toArray()['field_quote_text'];
        $quote_text = strip_tags($field_quote_text[0]['value']);
        return $quote_text;
    }

    /**
     * Validate if there is match with the quotes
     *
     * @param string $quote_text
     * @param string $search_term
     * @return boolean
     */
    private function hasMatchSearch(string $quote_text, string $search_term): bool {
        if (strpos($quote_text, $search_term) === false) {
            return FALSE;
        }
        
        return TRUE;
    }

    /**
     * Validate if the current iterated quote has match with paragraph id
     *
     * @param string $current_quote
     * @param string $paragraph_id
     * @return boolean
     */
    private function hasMatchParagraph(string $current_quote, string $paragraph_id): bool {
        if ($current_quote !== $paragraph_id) {
            return FALSE;
        }
        
        return TRUE;
    }

    /**
     * Validate the paragraph iterated in each quote returned
     *
     * @param array $paragraphs
     * @param integer $quote_key
     * @return void
     */
    private function validateParagraphsQuotes(array $paragraphs, int $quote_key) {
        foreach ($paragraphs as $paragraph) {
            $quote_text = $this->getQuoteText($paragraph);
            if (
                !$this->hasMatchSearch($quote_text, $this->getSearchTerm()) && 
                $this->hasMatchParagraph($this->current_quote, $paragraph->id->value)
            ) {
                unset($this->unfiltered_quotes[$quote_key]);
            }
        }
    }   

    /**
     * Main method to validate the view result
     *
     * @param array $unfiltered_quotes
     * @return void
     */
    public function validate(array $unfiltered_quotes) {
        foreach ($unfiltered_quotes as $key => $quote) {
            $paragraphs = $quote->_entity
              ->getFields()['field_quotes']
              ->referencedEntities();
            $this->setCurrentQuote($quote->node__field_quotes_field_quotes_target_id);
            $this->validateParagraphsQuotes($paragraphs, $key);
        }

        $this->setValidQuotes($this->getUnfilteredQuotes());
    }

}